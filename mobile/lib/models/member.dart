class Member {
  final String name;
  final String industry;
  final String company;
  final String avatar;

  Member({
    required this.name,
    required this.industry,
    required this.company,
    this.avatar = '',
  });

  static List<Member> get mockMembers {
    return [
      Member(name: 'Aashiq Amin', industry: 'Logistics', company: 'Amin Brothers PTY'),
      Member(name: 'Bhathiya Wijewardena', industry: 'Construction', company: 'B.W. Builders'),
      Member(name: 'Chatura Fernando', industry: 'Information Technology', company: 'SoftTech Solutions'),
      Member(name: 'Damika Perera', industry: 'Real Estate', company: 'Prime Residencies'),
      Member(name: 'Erandi Karunarathna', industry: 'Education', company: 'Learners Academy'),
      Member(name: 'Farhan Mohomed', industry: 'Fashion', company: 'TrendSetters'),
      Member(name: 'Gayan Ratnayake', industry: 'Hospitality', company: 'Hotel Ocean View'),
      Member(name: 'Hirunika Silva', industry: 'Law', company: 'Silva & Co.'),
      Member(name: 'Imthaz Kareem', industry: 'Automotive', company: 'Kareem Motors'),
      Member(name: 'Janaka Priyantha', industry: 'Agriculture', company: 'Green Harvest'),
      Member(name: 'Kasun Bandara', industry: 'Finance', company: 'Bandara FinSec'),
      Member(name: 'Laksith Perera', industry: 'Media', company: 'Vision Media'),
      Member(name: 'Mahesh Senanayake', industry: 'Manufacturing', company: 'Steel Works Ltd'),
      Member(name: 'Nadeera Jayasinghe', industry: 'Advertising', company: 'AdZone'),
      Member(name: 'Oshan De Silva', industry: 'Energy', company: 'De Silva Solar'),
      Member(name: 'Priyasala Peiris', industry: 'Healthcare', company: 'Smile Dental Clinic'),
      Member(name: 'Qadir Ahmed', industry: 'Import/Export', company: 'Ahmed Trading'),
      Member(name: 'Roshel Fernando', industry: 'Real Estate', company: 'Elite Haven'),
      Member(name: 'Sajith Premadasa', industry: 'Logistics', company: 'Sajith Logistics'),
      Member(name: 'Tharindu Rathnayake', industry: 'Retail', company: 'Lanka Supermarket'),
      Member(name: 'Udaya Gammanpila', industry: 'Information Technology', company: 'Udaya Tech'),
      Member(name: 'Vajira Abeywardena', industry: 'Architecture', company: 'Modern Space Design'),
      Member(name: 'Wasantha Perera', industry: 'Tourism', company: 'Lanka Holidays'),
      Member(name: 'Xavier Arulsamy', industry: 'Software Engineering', company: 'Xero Code'),
      Member(name: 'Yasas Keshawa', industry: 'Consultancy', company: 'Keshawa & Co.'),
      Member(name: 'Ziyad Mohamed', industry: 'Logistics', company: 'Z-Express'),
      Member(name: 'Amara Weerasinghe', industry: 'Jewellers', company: 'Amara Gems'),
      Member(name: 'Banuka Gamage', industry: 'Automotive', company: 'Gamage Garage'),
      Member(name: 'Chinthaka De Silva', industry: 'Textile', company: 'Lanka Prints'),
      Member(name: 'Dinuka Wijesooriya', industry: 'Banking', company: 'Peoples Bank'),
    ];
  }
}
