import 'dart:developer';

import 'package:collab_sphere/models/project.dart';
import 'package:get/get.dart';

class ProjectController extends GetxController {
  List<Project> projects = [];
  List<Project> topProjects = [];
  Map<String, Map<String, List<String>>> countrySchoolDepartments = {};
  forceUpdate() {
    log("projectController forceUpdate called");
    update();
  }
}

final ProjectController projectController = Get.put(ProjectController());
