# Development Docs

# Adding a new application version

1. Add the new application version under the `services/<app>/<version>` directory.
   These applications versions are additive (unlike kommander-applications).
2. Deploy the new application version and gather the images being used (looking at the default Helm chart values is useful as well).
3. Add the required images in the `hack/images.yaml` file.
4. Add the Kubernetes version compatibility range in `services/<app>/<version>/metadata.yaml`
