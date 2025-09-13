class Job {
  final String id;
  final String title;
  final String description;
  final String location;
  final String jobType;
  final DateTime deadline;
  final String email;

  Job({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.jobType,
    required this.deadline,
    required this.email,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['_id'],
      title: json['title'],
      description: json['description'],
      location: json['location'],
      jobType: json['jobType'],
      deadline: DateTime.parse(json['deadline']),
      email: json['email'] ?? '',
    );
  }
}
