local railsController = import 'rails_controller_common.libsonnet';

railsController.dashboard(type='web', defaultController='ProjectsController', defaultAction='show')
