package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"time"

	"github.com/prometheus/prometheus/pkg/rulefmt"
	"github.com/prometheus/prometheus/promql"
)

var (
	rulesDir        string
	prometheusHost  string
	offendingAlerts []string
	erroredAlerts   []string

	ignoredAlerts map[string]bool = make(map[string]bool)
)

type apiResponse struct {
	Status string `json:"status"`
	Data   struct {
		Result []interface{} `json:"result"`
	} `json:"data"`
}

func main() {
	if len(os.Args) < 3 {
		fmt.Printf("USAGE: %s rules-dir prometheus-host [alert-to-ignore,alert-to-ignore]\n", os.Args[0])
		os.Exit(1)
	}

	rulesDir = os.Args[1]
	prometheusHost = os.Args[2]

	if len(os.Args) > 3 {
		ignoredAlertsSeparated := os.Args[3]
		for _, ignoredAlert := range strings.Split(ignoredAlertsSeparated, ",") {
			ignoredAlerts[ignoredAlert] = true
		}
	}

	matches, err := filepath.Glob(fmt.Sprintf("%s/*.yml", rulesDir))
	if err != nil {
		log.Fatal(err)
	}

	for _, file := range matches {
		processFile(file)
	}

	var slackMessage string

	if len(erroredAlerts) > 0 {
		fmt.Println("====== Failed alerts (check above for errors):")
		slackMessage += "*Failed to check these alerts*\n\n"

		for _, alert := range erroredAlerts {
			fmt.Println(alert)
			slackMessage += fmt.Sprintf("* %s\n", alert)
		}
	}

	if len(slackMessage) > 0 {
		slackMessage += "\n"
	}

	if len(offendingAlerts) > 0 {
		fmt.Println("====== Possibly obsolete alerts:")
		slackMessage += fmt.Sprint("*Possibly obsolete alerts*\n\n")

		for _, alert := range offendingAlerts {
			fmt.Println(alert)
			slackMessage += fmt.Sprintf("* %s\n", alert)
		}
	}

	if (len(erroredAlerts) > 0) || (len(offendingAlerts) > 0) {
		if slackWebhookUrl := os.Getenv("SLACK_WEBHOOK_URL"); len(slackWebhookUrl) > 0 {
			channel := os.Getenv("SLACK_CHANNEL")
			data := url.Values{}

			if ciJobUrl := os.Getenv("CI_JOB_URL"); len(ciJobUrl) > 0 {
				slackMessage += fmt.Sprintf("\n:ci_failing: %s", ciJobUrl)
			}

			data.Set("payload", `{"channel":"`+channel+`","text":"`+slackMessage+`","mrkdwn":true}`)
			http.PostForm(slackWebhookUrl, data)
		}

		os.Exit(1)
	}
}

func processFile(file string) {
	ruleGroups, errs := rulefmt.ParseFile(file)
	if len(errs) > 0 {
		log.Fatalf("Error parsing file %v", errs)
	}

	groups := ruleGroups.Groups
	for _, group := range groups {
		for _, rule := range group.Rules {
			if rule.Alert == "" || ignoredAlerts[rule.Alert] {
				continue
			}

			selectors, err := extractSelectors(rule.Expr)
			if err != nil {
				log.Fatal(err)
			}

			present, err := checkSelectorsPresence(rule.Alert, selectors)
			if err != nil {
				log.Println(err)
				erroredAlerts = append(erroredAlerts, rule.Alert)
				continue
			}

			if !present {
				offendingAlerts = append(offendingAlerts, rule.Alert)
			}
		}
	}
}

func checkSelectorsPresence(alert string, selectors []string) (bool, error) {
	for _, selector := range selectors {
		hasResults, err := selectorHasResults(selector)
		if err != nil {
			return false, fmt.Errorf("Error getting results for '%s' (of alert %s): %v\n", selector, alert, err)
		}

		return hasResults, nil
	}

	return false, nil
}

func selectorHasResults(selector string) (bool, error) {
	now := time.Now().Unix()

	log.Printf("Checking %s\n", selector)

	requestUrl := fmt.Sprintf("%s/api/v1/query?query=%s&dedup=true&partial_response=true&start=%d&end=%d&step=14&max_source_resolution=0s",
		prometheusHost,
		url.PathEscape(selector),
		now,
		now-24*60*60,
	)

	response, err := http.Get(requestUrl)
	if err != nil {
		return false, err
	}

	if response.StatusCode != 200 {
		return false, fmt.Errorf("Status code = %d", response.StatusCode)
	}

	body, err := ioutil.ReadAll(response.Body)
	if err != nil {
		return false, fmt.Errorf("Error reading response body: %v", err)
	}

	var responseJson apiResponse
	if err := json.Unmarshal(body, &responseJson); err != nil {
		return false, fmt.Errorf("Failed response parsing, body was %s", body)
	}

	if status := responseJson.Status; status != "success" {
		return false, fmt.Errorf("`status` != 'success', got %s", status)
	}

	if len(responseJson.Data.Result) == 0 {
		return false, nil
	}

	return true, nil
}

func extractSelectors(exprStr string) ([]string, error) {
	expr, err := promql.ParseExpr(exprStr)
	if err != nil {
		return nil, fmt.Errorf("Error parsing the expression: %v", err)
	}

	// Good programmers traverse the tree, great programmers grep for what they
	// care for in the tree string representation -- Anonymous
	tree := promql.Tree(expr)
	selectorRegexp := regexp.MustCompile(`(?m)(?:VectorSelector|MatrixSelector) :: (.*)$`)
	rangeRegexp := regexp.MustCompile(`\[.*\]$`)

	selectors := []string{}

	for _, match := range selectorRegexp.FindAllStringSubmatch(tree, -1) {
		selector := rangeRegexp.ReplaceAllString(match[1], "")
		selectors = append(selectors, selector)
	}

	return selectors, nil
}
