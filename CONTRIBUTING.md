# K8s-m8g Contributing Guidelines

Thank you for considering to contribute to K8s-m8g project.

When contributing to this repository, please first discuss the change you wish to make via issue, email,
or by any other method with the owners of this repository before making a change.

## Pull Request Checklist

Before sending your pull requests, make sure you followed this list.

- Read [Contributing Guidelines](CONTRIBUTING.md)
- Read [Code of Conduct](CODE_OF_CONDUCT.md)
- Read [Commit Message Convention](https://chris.beams.io/posts/git-commit/)
- Read [How To](helpers/README.md) simplify your local development
- Set up the [Developer Certificate of Origin (DCO)](CONTRIBUTING.md#developer-certificate-of-origin-dco)
- Include a [License](CONTRIBUTING.md#license-on-the-top-of-file) at the top of new files
- Update the [Readme](README.md) with details of changes to the interface
- In case the pull request would update the version number, please edit the version number in all appropriate
  files e.g. [Chart.yaml](chart/Chart.yaml). The versioning scheme we use is [SemVer](http://semver.org/)
- You may merge the Pull Request once you have the sign-off of two other developers, or if you 
  don't have the permission to do that, you may request the second reviewer to merge it for you

## Developer Certificate of Origin (DCO)

The Developer Certificate of Origin (DCO) is a legally binding statement that asserts that you are the
creator of your contribution, and that you wish to allow K8s-m8g project to use your work.

Acknowledgement of this permission is done using a sign-off process in Git.
The sign-off is a simple line at the end of the explanation for the patch. The
text of the DCO is available on [developercertificate.org](https://developercertificate.org/).

If you are willing to agree to these terms, you just add a line to every git
commit message:

`Signed-off-by: Joe Smith <joe.smith@email.com>`

If you set your `user.name` and `user.email` as part of your git
configuration, you can sign your commit automatically with `git commit -s`.

Unfortunately, you have to use your real name (i.e., pseudonyms or anonymous
contributions cannot be made). This is because the DCO is a legally binding
document, granting the K8s-m8g project to use your work.

## License on the top of file

```
/*
  Copyright 2020 The K8s-m8g Authors. All Rights Reserved.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
      http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/
```
