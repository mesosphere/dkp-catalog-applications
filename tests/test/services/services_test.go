package services_test

import (
	"fmt"
	"path"

	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"

	sourcecontrollerv1beta1 "github.com/fluxcd/source-controller/api/v1beta1"

	"github.com/mesosphere/dkp-catalog-applications/tests/pkg/files"
)

const (
	ServicesDirectory    = "../../../services"
	HelmRepoDirectory    = "../../../helm-repositories"
	DefaultDirectoryName = "defaults"
	MetadataFileName     = "metadata.yaml"
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
	Context("directory structure", func() {
		// Get services names from services dir
		services, err := files.ListDirectories(ServicesDirectory)
		Expect(err).ShouldNot(HaveOccurred())
		Expect(len(services)).To(BeNumerically(">", 0))

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

	Context("helmrepositories", func() {
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
		}
	})
})
