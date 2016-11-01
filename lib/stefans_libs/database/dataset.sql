SELECT *
  FROM `test_db_genome`.`people`, `test_db_genome`.`creatures`,
       `test_db_genome`.`organism`, `test_db_genome`.`partizipatingSubjects`,
       `test_db_genome`.`datasets` JOIN `test_db_genome`.`scientists` ON `test_db_genome`.`datasets`.`scientist_id` = `test_db_genome`.`scientists`.`id` JOIN `test_db_genome`.`subjects` ON `test_db_genome`.`datasets`.`subject_id` = `test_db_genome`.`subjects`.`id` JOIN `test_db_genome`.`experiments` ON `test_db_genome`.`datasets`.`experiment_id` = `test_db_genome`.`experiments`.`id`
