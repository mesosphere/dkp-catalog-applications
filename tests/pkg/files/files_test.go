package files_test

import (
	"os"
	"path"

	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"

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
})