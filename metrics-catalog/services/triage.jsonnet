[
  { name: 'Web Frontend: gitlab.com web traffic', definition: import 'web.jsonnet' },
  { name: 'API: gitlab.com/api traffic', definition: import 'api.jsonnet' },
  { name: 'Git: git ssh and https traffic', definition: import 'git.jsonnet' },
  { name: 'CI runners', definition: import 'ci-runners.jsonnet' },
  { name: 'Container registry', definition: import 'registry.jsonnet' },
]
