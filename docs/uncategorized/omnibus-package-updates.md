# Omnibus package troubleshooting

## Symptoms

* Omnibus packages are set to disabled preventing automatic updates

## Troubleshooting

Check the omnibus role for the environment

```
# Example for the gprd environment
knife role show gprd-omnibus-version
```

See whether the `enable` attribute is set to `true`.

If it is not, ensure there are not any recent failed deployments by checking the
`#announcements` slack channel or recent [deployer pipelines](https://ops.gitlab.net/gitlab-com/gl-infra/deployer/pipelines)

If unsure, contact someone in the delivery team in `#g_delivery` about the error so they can
investigate.
