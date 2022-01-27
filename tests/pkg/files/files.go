package files

import (
	"os"
	"path"
	"path/filepath"

	helmcontrollerv2beta1 "github.com/fluxcd/helm-controller/api/v2beta1"
	sourcecontrollerv1beta1 "github.com/fluxcd/source-controller/api/v1beta1"
	"sigs.k8s.io/yaml"
)

const YamlFileExt = ".yaml"

type AppMetadata struct {
	DisplayName string   `yaml:"displayName"`
	Description string   `yaml:"description"`
	Category    []string `yaml:"category"`
	Scope       []string `yaml:"scope"`
	Overview    string   `yaml:"overview"`
	Icon        string   `yaml:"icon"`
}

func GetAppMetadata(mdFilePath string) (*AppMetadata, error) {
	bytes, err := os.ReadFile(mdFilePath)
	if err != nil {
		return nil, err
	}
	metaData := &AppMetadata{}
	if err = yaml.Unmarshal(bytes, metaData); err != nil {
		return nil, err
	}
	return metaData, nil
}

// ListDirectories returns the name of directories that are within the input directory (not recursive).
func ListDirectories(directory string) ([]string, error) {
	directories := []string{}
	files, err := os.ReadDir(directory)
	if err != nil {
		return nil, err
	}
	for _, file := range files {
		directories = append(directories, file.Name())
	}
	return directories, nil
}

// GetSubdirectoryMap returns a map containing the first level directory names and the list of subdirectory names
//
// Example structure
// ├── topLevelDir
//     └── firstLevelDir
//         ├── secondLevelDir1
//         ├── secondLevelDir2
// results in map[firstLevelDir:[secondLevelDir]].
func GetSubdirectoryMap(topLevelDirectory string) (map[string][]string, error) {
	directoryMap := make(map[string][]string)
	directoryList, err := ListDirectories(topLevelDirectory)
	if err != nil {
		return nil, err
	}
	for _, directory := range directoryList {
		subDirectories := []string{}
		files, err := os.ReadDir(path.Join(topLevelDirectory, directory))
		if err != nil {
			return nil, err
		}
		for _, file := range files {
			if file.IsDir() {
				subDirectories = append(subDirectories, file.Name())
			}
		}
		directoryMap[directory] = subDirectories
	}
	return directoryMap, nil
}

// GetHelmRepoURLs returns a map of HelmRepository names to url.
func GetHelmRepoURLs(
	dir string,
	helmRepos map[string]string,
) error {
	err := filepath.Walk(dir,
		func(path string, info os.FileInfo, err error) error {
			if err != nil {
				return err
			}
			if filepath.Ext(info.Name()) == YamlFileExt {
				bytes, _ := os.ReadFile(path)
				helmRepo := &sourcecontrollerv1beta1.HelmRepository{}
				err = yaml.Unmarshal(bytes, helmRepo)
				if err != nil {
					return err
				}
				if helmRepo.Kind == sourcecontrollerv1beta1.HelmRepositoryKind {
					helmRepos[helmRepo.Name] = helmRepo.Spec.URL
				}
			}
			return nil
		})
	return err
}

// ListHelmReleases returns a slice of all HelmReleases in the path.
func ListHelmReleases(dir string) ([]helmcontrollerv2beta1.HelmRelease, error) {
	var helmReleases []helmcontrollerv2beta1.HelmRelease

	err := filepath.Walk(dir,
		func(path string, info os.FileInfo, err error) error {
			if err != nil {
				return err
			}
			if filepath.Ext(info.Name()) == YamlFileExt {
				bytes, _ := os.ReadFile(path)
				helmRelease := &helmcontrollerv2beta1.HelmRelease{}
				err = yaml.Unmarshal(bytes, helmRelease)
				if err != nil {
					return err
				}
				if helmRelease.Kind == helmcontrollerv2beta1.HelmReleaseKind {
					helmReleases = append(helmReleases, *helmRelease)
				}
			}
			return nil
		})

	return helmReleases, err
}
