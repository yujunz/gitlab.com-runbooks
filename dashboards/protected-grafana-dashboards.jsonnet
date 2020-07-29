local union(sets) = std.foldl(function(memo, a) std.setUnion(std.set(a), memo), sets, []);

{
  dashboardUids:
    union([
      // Dashboards referenced from www-gitlab-com
      [
        '000000043',
        '000000044',
        '000000045',
        '000000159',
        '1EBTz3Dmz',
        'RZmbBr7mk',
        'SOn6MeNmk',
        'SaIRBwuWk',
        'WO9bDCnmz',
        '_03KZ-ZWz',
        'bd2Kl9Imk',
        'l8ifheiik',
        'rKo7Hg1Wk',
        'sXVh89Imk',
        'sv_pUrImz',
      ],
      // Dashboards referenced from inside the runbooks repo
      [
        '000000144',
        '000000153',
        '000000159',
        '000000167',
        '000000204',
        '000000244',
        '26q8nTzZz',
        '7Zq1euZmz',
        '8EAXC-AWz',
        '9GOIu9Siz',
        '9T-wXWbik',
        'JyaDfEWWz',
        'PwlB97Jmk',
        'RZmbBr7mk',
        'USVj3qHmk',
        'VE4pXc1iz',
        'WOtyonOiz',
        'ZOOh_aNik',
        'bd2Kl9Imk',
        'fasrTtKik',
        'llfd4b2ik',
        'oWe9aYxmk',
        'xSYVQ9Sik',
      ],
      // Dashboards that people have requested we save (for now!)
      [
        // mkaeppler: https://gitlab.com/gitlab-com/runbooks/-/merge_requests/2345#note_358065560
        'IGBZ5H_Zz',
        // hphilipps: osquery dashboard: https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/10504
        'fjSLYzRWz',
        // cmiskell: "please keep fleet overview": https://gitlab.com/gitlab-com/runbooks/-/merge_requests/2345#note_358366125
        'mnbqU9Smz',
        // T4cC0re: "I would like to keep" https://gitlab.com/gitlab-com/runbooks/-/merge_requests/2345#note_358837191
        'FvOt_fNZk',
        // joshlambert: "performance dashboards": 
        'performance-manage',
        'performance-create',
        'performance-plan',
        'performance-enablement',
        'performance-verify',
        'performance-release',
      ],

      // bjk's dashboards
      // https://gitlab.com/gitlab-com/runbooks/-/merge_requests/2345#note_358186936
      [
        'J0QFZXomk',
        'Qe6veT_mk',
        'pqlQq0xik',
        'x2SD_9Siz',
        '-l1W8kDWz',
        'JahkiwyWk',
        '9l09q0qik',
        'aBCbl9Smzv',
        'ozFp_56mk',
        'OYXV_5eik',
        'u0LwqvzWk',
        'L0HBvojWzv',
        '-gJSV0Yiz',
        'GTp20b1Zk',
        'O92e3k9Zkv',
        '1CgmG_zZz',
        '-UvftW1iz',
        'opwl5gSiz',
        'KqPVKRIiz',
        '64YQGnbZz',
        '_W4xKboWk',
        'nCKUurSmk',
        'Eo8BHoNZz',
        '4QhoV1tZk',
      ],
      // nnelson's dashboards
      // https://gitlab.com/gitlab-com/runbooks/-/merge_requests/2345#note_359096247
      [
        'W1v6W4JZk',
        'ApBISVEZk',
        'ZyUj4I2Zz',
        'Qv9RdwsZk',
        '7ef50NuWk',
        '-iBN4ZQZk',
        'yzukVGtZz',
        'O92e3k9Zk',
        'F2W0LV5Wk',
        '99GH9R8Wk',
      ],
    ]),

  folderTitles: [
    'Geo Service',
    'CI Runners Service',
    'infrafin',
    'Gitaly Service',
    'GitLab-Rails Service',
    'Kubernetes',
    'Operations',
    'Cloudflare',
    'PostgreSQL',
  ],
}
