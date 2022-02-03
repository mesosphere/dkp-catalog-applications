package files_test

import (
	"fmt"
	"os"
	"path"
	"path/filepath"
	"time"

	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"

	helmcontrollerv2beta1 "github.com/fluxcd/helm-controller/api/v2beta1"
	sourcecontrollerv1beta1 "github.com/fluxcd/source-controller/api/v1beta1"
	"sigs.k8s.io/yaml"

	"github.com/mesosphere/dkp-catalog-applications/tests/pkg/files"
)

var _ = Describe("Files", func() {
	It("can list directories", func() {
		topDir, err := os.MkdirTemp("", "")
		Expect(err).ShouldNot(HaveOccurred())
		defer os.RemoveAll(topDir)

		subDir, err := os.MkdirTemp(topDir, "")
		Expect(err).ShouldNot(HaveOccurred())
		defer os.RemoveAll(subDir)

		dirList, err := files.ListDirectories(topDir)
		Expect(err).ShouldNot(HaveOccurred())

		Expect(len(dirList)).To(BeNumerically(">", 0))
	})

	It("cannot list non-existent directories", func() {
		dirList, err := files.ListDirectories("foo")
		Expect(err).Should(HaveOccurred())
		Expect(dirList).To(BeNil())
	})

	It("can get map of subdirectories", func() {
		topDir, err := os.MkdirTemp("", "top")
		Expect(err).ShouldNot(HaveOccurred())
		defer os.RemoveAll(topDir)

		firstLevelDir, err := os.MkdirTemp(topDir, "first")
		Expect(err).ShouldNot(HaveOccurred())
		defer os.RemoveAll(firstLevelDir)

		secondLevelDir, err := os.MkdirTemp(firstLevelDir, "second")
		Expect(err).ShouldNot(HaveOccurred())
		defer os.RemoveAll(secondLevelDir)

		subDirMap, err := files.GetSubdirectoryMap(topDir)
		Expect(err).ShouldNot(HaveOccurred())

		_, firstLevelDirName := path.Split(firstLevelDir)
		_, secondLevelDirName := path.Split(secondLevelDir)

		Expect(subDirMap[firstLevelDirName]).To(Equal([]string{secondLevelDirName}))
	})

	It("can't get map of subdirectories", func() {
		subDirMap, err := files.GetSubdirectoryMap("foo")
		Expect(err).Should(HaveOccurred())
		Expect(subDirMap).Should(BeEmpty())
	})

	Context("with HelmRelease test data", func() {
		It("can list HelmReleases", func() {
			// We are creating the helm release test files here because if committed to the repo
			// the k-cli will attempt to parse and download the charts
			dir, err := createValidHelmRelease()
			Expect(err).ShouldNot(HaveOccurred())
			defer os.RemoveAll(dir)
			helmReleases, err := files.ListHelmReleases(dir)
			Expect(err).ShouldNot(HaveOccurred())

			Expect(len(helmReleases)).To(BeNumerically(">", 0))
		})

		It("cannot list HelmReleases", func() {
			_, err := files.ListHelmReleases("./foo/bar")
			Expect(err).Should(HaveOccurred())
		})
	})

	Context("with HelmRepository test data", func() {
		It("can get HelmRepositories", func() {
			helmRepos := make(map[string]string)
			// We are creating the helm repo test files here because if committed to the repo
			// the k-cli will attempt to parse and download the charts
			dir, err := createValidHelmRepo()
			Expect(err).ShouldNot(HaveOccurred())
			defer os.RemoveAll(dir)
			fmt.Println(dir)
			err = files.GetHelmRepoURLs(dir, helmRepos)
			Expect(err).ShouldNot(HaveOccurred())
			Expect(len(helmRepos)).To(BeNumerically(">", 0))
		})

		It("cannot get HelmRepositories", func() {
			helmRepos := make(map[string]string)
			err := files.GetHelmRepoURLs("./foo/bar/", helmRepos)
			Expect(err).Should(HaveOccurred())
		})
	})
})

func createValidHelmRepo() (string, error) {
	dir, err := os.MkdirTemp("", "")
	if err != nil {
		return "", err
	}
	helmRepo := sourcecontrollerv1beta1.HelmRepository{
		TypeMeta: metav1.TypeMeta{
			Kind:       sourcecontrollerv1beta1.HelmRepositoryKind,
			APIVersion: sourcecontrollerv1beta1.GroupVersion.String(),
		},
		Spec: sourcecontrollerv1beta1.HelmRepositorySpec{
			URL:      "https://foo.bar",
			Interval: metav1.Duration{Duration: time.Second},
		},
	}
	bytes, err := yaml.Marshal(&helmRepo)
	if err != nil {
		return "", err
	}
	err = os.WriteFile(filepath.Join(dir, "helmrepo.yaml"), bytes, 0o600)
	if err != nil {
		return "", err
	}
	return dir, nil
}

func createValidHelmRelease() (string, error) {
	dir, err := os.MkdirTemp("", "")
	if err != nil {
		return "", err
	}
	helmRelease := helmcontrollerv2beta1.HelmRelease{
		TypeMeta: metav1.TypeMeta{
			Kind:       helmcontrollerv2beta1.HelmReleaseKind,
			APIVersion: helmcontrollerv2beta1.GroupVersion.String(),
		},
		Spec: helmcontrollerv2beta1.HelmReleaseSpec{
			Chart: helmcontrollerv2beta1.HelmChartTemplate{
				Spec: helmcontrollerv2beta1.HelmChartTemplateSpec{
					Chart: "foo",
					SourceRef: helmcontrollerv2beta1.CrossNamespaceObjectReference{
						Kind:      sourcecontrollerv1beta1.HelmRepositoryKind,
						Name:      "foo",
						Namespace: "foo",
					},
				},
			},
		},
	}
	bytes, err := yaml.Marshal(&helmRelease)
	if err != nil {
		return "", err
	}
	err = os.WriteFile(filepath.Join(dir, "helmrelease.yaml"), bytes, 0o600)
	if err != nil {
		return "", err
	}
	return dir, nil
}
