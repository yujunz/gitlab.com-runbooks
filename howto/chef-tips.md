## Chef best practices

### `role` vs `roles`

`knife (search|ssh|..) role:my-role ...` returns only nodes for which `my-role` is specified in their run_list, not nested ones.

`knife (search|ssh|..) roles:my-role ...` returns all nodes which has `my-role`, directly and nestly specified.

 
### Update IP of chef node

Create or update file `/etc/ipaddress.txt` with desired IP address (or run `curl ifconfig.co | sudo tee /etc/ipaddress.txt`) and run chef-client.

