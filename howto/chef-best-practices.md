## Chef best practices

### `role` vs `roles`

`knife (search|ssh|..) role:my-role ...` returns only nodes for which `my-role` is specified in their run_list, not nested ones.

`knife (search|ssh|..) roles:my-role ...` returns all nodes which has `my-role`, directly and nestly specified.

 
