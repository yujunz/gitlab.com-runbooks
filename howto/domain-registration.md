# Domain Registration

So you want to register a domain? This is the guide for you!

We register our domains with AWS Route53 and also use them for DNS. If the TLD you wish to use is not available at AWS, please
use Gandi[https://admin.gandi.net].
In order to register a domain for GitLab, you will need to have
access to our AWS account. Please create an [infrastructure issue](https://gitlab.com/gitlab-com/infrastructure/issues/new)
if you need access.

## AWS Instructions

1. Log in to the [AWS web interface](https://console.aws.amazon.com/route53/home?#DomainListing:) and go to the Route53 section (the link should take you directly there).
1. Go to the `Registered Domains` tab and click `Register Domain` at the top.
1. Search for the desired domain name. AWS will list the availability of the requested domain as well as some suggested alternatives.
1. Select the domain(s) you want and proceed to the next screen where it will ask you about the registrant contact info. The default is fine.
1. On the next page, review the domain(s) and registrant info. By default, registration will automatically create and set up DNS to be hosted with Route53.
1. Accept the terms and complete purchase. The registration will be submitted, but it may take some time for the registration to complete. You can see the status of the registration on the [Pending Requsts](https://console.aws.amazon.com/route53/home?region=us-east-1#DomainRequests:) page.

Once the registration is complete you can begin adding records and using
the domain immediately, though depending on the TLD there may be some
propagation time.

## Gandi Instructions

1. Log in to the [Gandi Admin panel](https://admin.gandi.net), with the creds in 1Password.
2. Click on the Domains tab in the left panel.
3. Click on Register in the upper right corner and type in the domain you wish to register and choose "register".
4. Click the "add to cart" button next to the domains in question.
5. Click the cart button in the upper right.
6. Use the default ownership info.
7. Review the shopping cart info and accept the terms of the registration.
8. Choose to pay with the GitLab AMEX card.
9. Create the domain in Route53 DNS and set the nameservers to the assigned Route53 servers.
