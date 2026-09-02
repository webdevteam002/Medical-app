-- CreateIndex
CREATE INDEX "exam_attempt_details_attempt_id_idx" ON "exam_attempt_details"("attempt_id");

-- CreateIndex
CREATE INDEX "exam_attempt_details_question_id_idx" ON "exam_attempt_details"("question_id");

-- CreateIndex
CREATE INDEX "exams_subject_id_idx" ON "exams"("subject_id");

-- CreateIndex
CREATE INDEX "exams_is_published_subject_id_idx" ON "exams"("is_published", "subject_id");

-- CreateIndex
CREATE INDEX "materials_subject_id_idx" ON "materials"("subject_id");

-- CreateIndex
CREATE INDEX "materials_topic_id_idx" ON "materials"("topic_id");

-- CreateIndex
CREATE INDEX "materials_is_published_subject_id_idx" ON "materials"("is_published", "subject_id");

-- CreateIndex
CREATE INDEX "questions_subject_id_idx" ON "questions"("subject_id");

-- CreateIndex
CREATE INDEX "questions_subject_id_is_published_idx" ON "questions"("subject_id", "is_published");

-- CreateIndex
CREATE INDEX "subjects_year_id_idx" ON "subjects"("year_id");

-- CreateIndex
CREATE INDEX "topics_subject_id_idx" ON "topics"("subject_id");
