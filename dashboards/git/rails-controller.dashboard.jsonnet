local railsController = import 'rails_controller_common.libsonnet';

railsController.dashboard(type='git', defaultController='Repositories::GitHttpController', defaultAction='git_upload_pack')
