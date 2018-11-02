package main

import (
	"flag"
	"fmt"
	"io/ioutil"
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
		panic(err)
	}
	return u.Hostname()
}

func (c PingdomCheck) encryption() bool {
	u, err := url.Parse(c.URL)
	if err != nil {
		panic(err)
	}
	return u.Scheme == "https"
}

func (c PingdomCheck) path() string {
	u, err := url.Parse(c.URL)
	if err != nil {
		panic(err)
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
			panic("Unable to find team " + v)
		}
		teamID, err := strconv.Atoi(team.ID)
		if err != nil {
			panic("TeamID is not an integer: " + team.ID)
		}

		teamIds = append(teamIds, teamID)
	}

	integrationIDs := []int{}
	for _, v := range c.Integrations {
		integrationID, ok := integrationIDMap[v]
		if !ok {
			panic("Unable to find integration " + v)
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
		Tags:                  strings.Join(tags, ","),
		TeamIds:               teamIds,
		IntegrationIds:        integrationIDs,
		NotifyWhenBackup:      c.NotifyWhenRestored,
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
			fmt.Printf("%v has not been deployed: %v\n", v.name(), deployedChecks)
			result = append(result, v)
		}
	}
	return result
}

func main() {
	configurationFile := flag.String("config", "pingdom.yml", "Configuration File")

	yamlFile, err := ioutil.ReadFile(*configurationFile)
	if err != nil {
		panic(err)
	}
	var pingdomChecks PingdomChecks
	err = yaml.Unmarshal(yamlFile, &pingdomChecks)
	fmt.Printf("%+v\n", pingdomChecks)

	configMap := make(map[string]PingdomCheck)
	for _, v := range pingdomChecks.Checks {
		configMap[v.name()] = v
	}

	integrationIdMap := make(map[string]int)
	for _, v := range pingdomChecks.Integrations {
		integrationIdMap[v.Name] = v.ID
	}

	client := pingdom.NewMultiUserClient(os.Getenv("PINGDOM_USERNAME"), os.Getenv("PINGDOM_PASSWORD"), os.Getenv("PINGDOM_APPKEY"), os.Getenv("PINGDOM_ACCOUNT_EMAIL"))

	teams, err := client.Teams.List()
	if err != nil {
		panic(err)
	}

	teamMap := make(map[string]pingdom.TeamResponse)
	for _, v := range teams {
		teamMap[v.Name] = v
	}

	checks, err := client.Checks.List()
	if err != nil {
		panic(err)
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
		check, err := client.Checks.Create(v.getCheck(pingdomChecks, teamMap, integrationIdMap))
		if err != nil {
			panic(err)
		}
		fmt.Println("Created check:", check) // {ID, Name}
	}

	// Do the updates
	for _, update := range forUpdate {
		v, ok := configMap[update.Name]
		if !ok {
			panic("Unable to lookup " + update.Name)
		}

		check, err := client.Checks.Update(update.ID, v.getCheck(pingdomChecks, teamMap, integrationIdMap))
		if err != nil {
			panic(err)
		}
		fmt.Println("Updated check:", check) // {ID, Name}
	}

	// Do the deletions
	for _, d := range forRemoval {
		check, err := client.Checks.Delete(d.ID)
		if err != nil {
			panic(err)
		}
		fmt.Println("Deleted check:", check) // {ID, Name}
	}
}
