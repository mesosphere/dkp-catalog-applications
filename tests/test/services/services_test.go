package services_test

import (
	"fmt"
	"path"

	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"

	sourcecontrollerv1beta1 "github.com/fluxcd/source-controller/api/v1beta1"
	// kustomizebuild "sigs.k8s.io/kustomize/api/krusty"
	// "sigs.k8s.io/kustomize/kyaml/filesys"
	"github.com/mesosphere/dkp-catalog-applications/tests/pkg/files"
)

const (
	ConfigMapKind = "ConfigMap"
	ServicesDirectory    = "../../../services"
	HelmRepoDirectory    = "../../../helm-repositories"
	DefaultDirectoryName = "defaults"
	MetadataFileName     = "metadata.yaml"
	DefaultConfigMapFileName = "cm.yaml"
)

var _ = Describe("Services", func() {
	// For each service the directory structure should be:
	// services/kafka-operator
	// ├── 0.20.0
	// │   ├── defaults
	// │   │   ├── cm.yaml
	// │   │   └── kustomization.yaml
	// │   ├── kafka-operator.yaml
	// │   └── kustomization.yaml
	// └── metadata.yaml

	var services []string

	BeforeEach(func() {
		// Get services names from services dir
		services, err := files.ListDirectories(ServicesDirectory)
		Expect(err).ShouldNot(HaveOccurred())
		Expect(len(services)).To(BeNumerically(">", 0))
	})	

	Context("directory structure", func() {
		// Get service versions from list of services
		serviceVersions, err := files.GetSubdirectoryMap(ServicesDirectory)
		Expect(err).ShouldNot(HaveOccurred())

		// Validate each services file structure
		for service, versionList := range serviceVersions {
			It(fmt.Sprintf("%s should have the proper file structure", service), func() {
				// Validate metadata.yaml exists
				Expect(path.Join(ServicesDirectory, service, MetadataFileName)).To(BeAnExistingFile())
			})
			for _, version := range versionList {
				versionPath := path.Join(ServicesDirectory, service, version)
				It(fmt.Sprintf("version %s of %s should have the proper file structure", version, service), func() {
					Expect(err).ShouldNot(HaveOccurred())
					// Validate "defaults" directory exists
					Expect(path.Join(versionPath, DefaultDirectoryName)).To(BeADirectory())
				})
			}
		}
	})

	// TODO: enable this once https://github.com/kubernetes-sigs/kustomize/issues/4409 is resolved
	// Context("kustomizations", func() {
	// 	// equivalent to a "kustomize build FILEPATH" command run
	// 	kBuild := krusty.MakeKustomizer(krusty.MakeDefaultOptions())
	// 	memFs := filesys.MakeFsInMemory()

	// 	for _, service := range services {
	// 		versions := ListDirectories(path.join(ServicesDirectory, service))
	// 		for _, version := range versions {
	// 			kustomizationPath := path.join(path.join(ServicesDirectory, service, version))
	// 			It("should be able to run kustomize build", func() {
	// 				_, err := kBuild.Run(memFs, kustomizationPath)
	// 			})
	// 		}
	// 	}
	// })

	Context("helmreleases", func() {
		// Get HelmRepository name/urls map
		helmRepos := make(map[string]string)
		err := files.GetHelmRepoURLs(HelmRepoDirectory, helmRepos)
		Expect(err).ShouldNot(HaveOccurred())

		// Get list of all helm releases
		helmReleases, err := files.ListHelmReleases(ServicesDirectory)
		Expect(err).ShouldNot(HaveOccurred())

		Expect(len(helmReleases)).To(BeNumerically(">", 0))
		// Validate each HelmRelease references an existing HelmRepository
		for _, helmRelease := range helmReleases {
			helmRelease := helmRelease
			It(fmt.Sprintf("the %s HelmRelease should reference a HelmRepository that exists in this repository", helmRelease.Name), func() {
				Expect(helmRelease.Spec.Chart.Spec.SourceRef.Kind).Should(Equal(sourcecontrollerv1beta1.HelmRepositoryKind))
				Expect(helmRepos).To(HaveKey(helmRelease.Spec.Chart.Spec.SourceRef.Name),
					fmt.Sprintf("the %s HelmRelease references a HelmRepository (%s) that doesn't exist in the %s directory",
						helmRelease.Name, helmRelease.Spec.Chart.Spec.SourceRef.Name, HelmRepoDirectory))
			})

			It("should reference a ConfigMap that exists in default directory", func () {
				configMapRefs := helmRelease.Spec.ValuesFrom
				chartVer := helmRelease.Spec.Chart.Spec.Version
				Expect(len(helmRelease.Spec.ValuesFrom)).To(BeNumerically(">", 0))
				defaultMapFound := false
				for _, configMapRef := range configMapRefs {
					if configMapRef.Kind == ConfigMapKind {
						Expect(configMapRef.Name).To(ContainSubstring(chartVer))
						serviceName := helmRelease.ObjectMeta.Name
						configMapFilePath := path.Join(ServicesDirectory, serviceName, chartVer, DefaultDirectoryName, DefaultConfigMapFileName)
						Expect(configMapFilePath).To(BeAnExistingFile())
						configMap, err := files.GetConfigMapObjectFromFile(configMapFilePath)
						Expect(err).ShouldNot(HaveOccurred())
						Expect(configMapRef.Name).Should(Equal(configMap.ObjectMeta.Name))
						defaultMapFound = true
						break
					}
				}
				Expect(defaultMapFound).To(Equal(true))
			})
		}
	})

	Context("app metadata files", func() {
		for _, service := range services {
			metadataFilePath := path.Join(ServicesDirectory, service, MetadataFileName)
			metadata, err := files.GetAppMetadataFromFile(metadataFilePath)
			Expect(err).ShouldNot(HaveOccurred())

			It("should have non-empty displayName", func() {
				Expect(len(metadata.DisplayName)).To(BeNumerically(">", 0))
			})
			
			It("should have non-empty description", func() {
				Expect(len(metadata.Description)).To(BeNumerically(">", 0))
			})
			
			It("should have non-empty category", func() {
				Expect(len(metadata.Category)).To(BeNumerically(">", 0))
			})

			It("should have non-empty scope(s) with supported values", func() {
				Expect(len(metadata.Scope)).To(BeNumerically(">", 0))
				for _, sc := range metadata.Scope {
					Expect(sc).To(BeElementOf("workspace", "project"))
				}
			})
			
			It ("should have non-empty overview", func() {
				Expect(len(metadata.Overview)).To(BeNumerically(">", 0))
			})
			
			It ("should have non-empty icon", func() {
				Expect(len(metadata.Icon)).To(BeNumerically(">", 0))
			})	
		}
	})
})
