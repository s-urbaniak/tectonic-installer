package main

import (
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"
	"runtime"
	"time"

	"github.com/coreos/tectonic-installer/installer/pkg/terraform"
	"github.com/kardianos/osext"
)

var tfFile = `resource "random_id" "cluster_id" {
  byte_length = 16
}

output "id" {
  value = "${random_id.cluster_id.hex}"
}`

func newExecutor() (*terraform.Executor, error) {
	binaryPath, err := osext.ExecutableFolder()
	if err != nil {
		return nil, err
	}

	log.Println("binaryPath", binaryPath)
	clusterName := "kalmog"
	exPath := filepath.Join(binaryPath, "clusters", clusterName+time.Now().Format("_2006-01-02_15-04-05"))

	clusterPluginDir := filepath.Join(
		exPath,
		"terraform.d",
		"plugins",
		fmt.Sprintf("%s_%s", runtime.GOOS, runtime.GOARCH),
	)

	log.Println("creating", clusterPluginDir)

	err = os.MkdirAll(clusterPluginDir, os.ModeDir|0755)
	if err != nil {
		return nil, err
	}

	err = ioutil.WriteFile(filepath.Join(exPath, "main.tf"), []byte(tfFile), 0644)
	if err != nil {
		log.Fatal(err)
	}

	ex, err := terraform.NewExecutor(exPath)
	if err != nil {
		return nil, err
	}

	return ex, nil
}

func main() {
	ex, err := newExecutor()
	if err != nil {
		log.Fatal(err)
	}

	_, done, err := ex.Execute("init")
	if err != nil {
		log.Fatal(err)
	}
	<-done

	_, done, err = ex.Execute("plan")
	if err != nil {
		log.Fatal(err)
	}
	<-done

	_, done, err = ex.Execute("apply")
	if err != nil {
		log.Fatal(err)
	}
	<-done

	log.Println(ex)
}
