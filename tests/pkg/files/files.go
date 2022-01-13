package files

import (
	"os"
	"path"
)

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
