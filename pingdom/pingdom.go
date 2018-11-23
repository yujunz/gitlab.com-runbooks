package main

import (
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"net/url"
	"os"
	"strconv"
	"strings"

	pingdom "github.com/russellcardullo/go-pingdom/pingdom"
	yaml "gopkg.in/yaml.v2"
)

// PingdomCheckDefaults represents the default values
type PingdomCheckDefaults struct {
	TimeoutMS         int `yaml:"timeout_ms"`
	ResolutionMinutes int `yaml:"resolution_minutes"`
}

// PingdomCheck represents an individual check
type PingdomCheck struct {
	URL                string
	TimeoutMS          int      `yaml:"timeout_ms"`
	ResolutionMinutes  int      `yaml:"resolution_minutes"`
	Teams              []string `yaml:"teams"`
	Tags               []string `yaml:"tags"`
	Integrations       []string `yaml:"integrations"`
	NotifyWhenRestored bool     `yaml:"notify_when_restored"`
}

// PingdomChecks represents the YAML config structure
type PingdomChecks struct {
	UniqueTag    string `yaml:"unique_tag"`
	Defaults     PingdomCheckDefaults
	Integrations []struct {
		Name string `yaml:"name"`
		ID   int    `yaml:"id"`
	}
	Checks []PingdomCheck
}

func (c PingdomCheck) name() string {
	return fmt.Sprintf("check:%v", c.URL)
}

func (c PingdomCheck) hostname() string {
	u, err := url.Parse(c.URL)
	if err != nil {
		log.Fatalf("unable to parse URL: %v", err)
	}
	return u.Hostname()
}

func (c PingdomCheck) encryption() bool {
	u, err := url.Parse(c.URL)
	if err != nil {
		log.Fatalf("unable to parse URL: %v", err)
	}
	return u.Scheme == "https"
}

func (c PingdomCheck) path() string {
	u, err := url.Parse(c.URL)
	if err != nil {
		log.Fatalf("unable to parse URL: %v", err)
	}

	return u.Path + u.RawQuery
}

func (c PingdomCheck) getCheck(config PingdomChecks, teamMap map[string]pingdom.TeamResponse, integrationIDMap map[string]int) pingdom.Check {
	timeoutMS := c.TimeoutMS
	if timeoutMS == 0 {
		timeoutMS = config.Defaults.TimeoutMS
	}
	if timeoutMS == 0 {
		timeoutMS = 5000
	}

	resolutionMinutes := c.ResolutionMinutes
	if resolutionMinutes == 0 {
		resolutionMinutes = config.Defaults.ResolutionMinutes
	}
	if resolutionMinutes == 0 {
		resolutionMinutes = 5
	}

	teamIds := []int{}
	for _, v := range c.Teams {
		team, ok := teamMap[v]
		if !ok {
			log.Fatalf("Unable to find team %v", v)
		}
		teamID, err := strconv.Atoi(team.ID)
		if err != nil {
			log.Fatalf("TeamID is not an integer: %s", team.ID)
		}

		teamIds = append(teamIds, teamID)
	}

	integrationIDs := []int{}
	for _, v := range c.Integrations {
		integrationID, ok := integrationIDMap[v]
		if !ok {
			log.Fatalf("Unable to find integration %v", v)
		}

		integrationIDs = append(integrationIDs, integrationID)
	}

	tags := []string{config.UniqueTag}
	for _, v := range c.Tags {
		if v != "" {
			tags = append(tags, v)
		}
	}

	return &pingdom.HttpCheck{
		Name:                  c.name(),
		Hostname:              c.hostname(),
		Url:                   c.path(),
		Encryption:            c.encryption(),
		Resolution:            resolutionMinutes,
		ResponseTimeThreshold: timeoutMS,
		Tags:             strings.Join(tags, ","),
		TeamIds:          teamIds,
		IntegrationIds:   integrationIDs,
		NotifyWhenBackup: c.NotifyWhenRestored,
	}
}

func findChecksForRemoval(configMap map[string]PingdomCheck, deployedChecks map[string]pingdom.CheckResponse) []pingdom.CheckResponse {
	var result []pingdom.CheckResponse
	for k, v := range deployedChecks {
		if _, ok := configMap[k]; !ok {
			result = append(result, v)
		}
	}
	return result
}

func findChecksForUpdate(configMap map[string]PingdomCheck, deployedChecks map[string]pingdom.CheckResponse) []pingdom.CheckResponse {
	var result []pingdom.CheckResponse
	for k, v := range deployedChecks {
		if _, ok := configMap[k]; ok {
			result = append(result, v)
		}
	}
	return result
}

func findChecksForInsertion(configMap map[string]PingdomCheck, deployedChecks map[string]pingdom.CheckResponse) []PingdomCheck {
	var result []PingdomCheck
	for _, v := range configMap {
		_, present := deployedChecks[v.name()]

		if !present {
			log.Printf("%v has not been deployed: %v", v.name(), deployedChecks)
			result = append(result, v)
		}
	}
	return result
}

type pingdomCheckUpdater interface {
	insert(check pingdom.Check) error
	update(id int, check pingdom.Check) error
	delete(id int) error
}

type dryRunUpdater struct{}

func (c dryRunUpdater) insert(check pingdom.Check) error {
	log.Printf("dry-run: will create: %v", check)
	return nil
}

func (c dryRunUpdater) update(id int, check pingdom.Check) error {
	log.Printf("dry-run: will update: %v", check)
	return nil
}

func (c dryRunUpdater) delete(id int) error {
	log.Printf("dry-run: will delete: %d", id)
	return nil
}

type executingUpdater struct {
	client *pingdom.Client
}

func (c executingUpdater) insert(check pingdom.Check) error {
	response, err := c.client.Checks.Create(check)
	if err != nil {
		return err
	}
	log.Println("execute: created check:", response)
	return nil
}

func (c executingUpdater) update(id int, check pingdom.Check) error {
	response, err := c.client.Checks.Update(id, check)
	if err != nil {
		return err
	}
	log.Println("execute: updated check:", response)
	return nil
}

func (c executingUpdater) delete(id int) error {
	response, err := c.client.Checks.Delete(id)
	if err != nil {
		return err
	}
	log.Println("execute: deleted check:", response)
	return nil
}

var (
	configurationFile = flag.String("config", "pingdom.yml", "Configuration File")
	dryRun            = flag.Bool("dry-run", false, "Enable dry-run mode")
)

func newClient() (*pingdom.Client, error) {
	username := os.Getenv("PINGDOM_USERNAME")
	password := os.Getenv("PINGDOM_PASSWORD")
	appkey := os.Getenv("PINGDOM_APPKEY")
	accountEmail := os.Getenv("PINGDOM_ACCOUNT_EMAIL")

	if username == "" || password == "" || appkey == "" || accountEmail == "" {
		return nil, fmt.Errorf("please configure the PINGDOM_USERNAME, PINGDOM_PASSWORD, PINGDOM_APPKEY, PINGDOM_ACCOUNT_EMAIL environment variables")
	}

	client := pingdom.NewMultiUserClient(username, password, appkey, accountEmail)
	return client, nil
}

func main() {
	flag.Parse()

	yamlFile, err := ioutil.ReadFile(*configurationFile)
	if err != nil {
		log.Fatalf("unable to parse configuration %v: %v", *configurationFile, err)
	}
	var configuration PingdomChecks
	err = yaml.Unmarshal(yamlFile, &configuration)

	configMap := make(map[string]PingdomCheck)
	for _, v := range configuration.Checks {
		configMap[v.name()] = v
	}

	integrationIDMap := make(map[string]int)
	for _, v := range configuration.Integrations {
		integrationIDMap[v.Name] = v.ID
	}

	client, err := newClient()
	if err != nil {
		log.Fatalf("unable to connect: %v", err)
	}

	var updater pingdomCheckUpdater
	if *dryRun {
		updater = dryRunUpdater{}
	} else {
		updater = executingUpdater{client: client}
	}

	teams, err := client.Teams.List()
	if err != nil {
		log.Fatalf("unable to list teams: %v", err)
	}

	teamMap := make(map[string]pingdom.TeamResponse)
	for _, v := range teams {
		teamMap[v.Name] = v
	}

	checks, err := client.Checks.List()
	if err != nil {
		log.Fatalf("unable to list checks: %v", err)
	}

	deployedChecks := make(map[string]pingdom.CheckResponse)
	for _, v := range checks {
		if strings.HasPrefix(v.Name, "check:") {
			deployedChecks[v.Name] = v
		}
	}

	forRemoval := findChecksForRemoval(configMap, deployedChecks)
	forUpdate := findChecksForUpdate(configMap, deployedChecks)
	forInsertion := findChecksForInsertion(configMap, deployedChecks)

	// Do the inserts
	for _, v := range forInsertion {
		err := updater.insert(v.getCheck(configuration, teamMap, integrationIDMap))
		if err != nil {
			log.Fatalf("insert failed: %v", err)
		}
	}

	// Do the updates
	for _, update := range forUpdate {
		v, ok := configMap[update.Name]
		if !ok {
			log.Fatalf("Unable to lookup %s", update.Name)
		}

		err := updater.update(update.ID, v.getCheck(configuration, teamMap, integrationIDMap))
		if err != nil {
			log.Fatalf("update failed: %v", err)
		}
	}

	// Do the deletions
	for _, d := range forRemoval {
		err := updater.delete(d.ID)
		if err != nil {
			log.Fatalf("delete failed: %v", err)
		}
	}
}
