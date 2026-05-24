import 'enrollment.dart';

class CourseLesson {
  final String id;
  final String title;
  final String subtitle;
  final String duration;

  const CourseLesson({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.duration,
  });
}

List<CourseLesson> defaultCourseLessons(Enrollment enrollment) {
  final title = enrollment.courseTitle;
  final category = enrollment.category.isEmpty ? 'course' : enrollment.category;

  return [
    CourseLesson(
      id: 'orientation',
      title: 'Course orientation',
      subtitle: 'Understand the roadmap for $title.',
      duration: '8 min',
    ),
    CourseLesson(
      id: 'foundation',
      title: 'Core foundations',
      subtitle: 'Build the important concepts in this $category track.',
      duration: '22 min',
    ),
    CourseLesson(
      id: 'practice',
      title: 'Guided practice',
      subtitle: 'Apply concepts with teacher-led examples.',
      duration: '30 min',
    ),
    CourseLesson(
      id: 'doubt_session',
      title: 'Doubt clearing',
      subtitle: 'Collect questions before the next live class.',
      duration: '15 min',
    ),
    CourseLesson(
      id: 'revision',
      title: 'Revision checklist',
      subtitle: 'Review the key points before moving ahead.',
      duration: '12 min',
    ),
  ];
}

double progressFor({
  required int completedCount,
  required int totalCount,
}) {
  if (totalCount <= 0) return 0;
  return completedCount / totalCount;
}
