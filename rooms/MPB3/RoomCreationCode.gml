if (variable_global_exists("gameParams") && global.gameParams.practiceMode) {
    instance_create_layer(0, 0, "Instances", objPracticeController);
}
