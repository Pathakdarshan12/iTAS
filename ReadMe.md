# Intelligent Talent Acquisition System

This project is a mini-project developed as part of the Master's in Computer Application program. The Intelligent Talent Acquisition System leverages advanced technologies like deep learning and machine learning to streamline and enhance the recruitment process. This system automates tasks such as resume parsing, skill matching, and interview scheduling, making hiring faster, more accurate, and more efficient.

## Table of Contents

- [Introduction](#introduction)
- [Features](#features)
- [Technologies Used](#technologies-used)
- [System Requirements](#system-requirements)
- [Installation](#installation)
- [Usage](#usage)
- [Folder Structure](#folder-structure)
- [Database Design](#database-design)
- [Contributing](#contributing)
- [Authors](#authors)
- [License](#license)

## Introduction

The "Intelligent Talent Acquisition System" aims to revolutionize the hiring process by leveraging deep learning and machine learning techniques to automate and optimize various aspects of recruitment, including resume parsing, skill matching, and interview scheduling. This system provides a user-friendly interface for recruiters and enhances the efficiency and accuracy of candidate assessment.

## Features

- **Automated Resume Parsing:** Utilizes deep learning models for accurate extraction of candidate information from resumes.
- **Dynamic Skill Matching Algorithms:** Machine learning algorithms dynamically match candidate skills with job requirements.
- **Intuitive Recruitment Dashboard:** Provides an easy-to-use interface for managing job postings, candidate profiles, and interview scheduling.
- **Predictive Analytics:** Estimates time-to-hire to aid in workforce planning and management.
- **Security Measures:** Implements robust security features such as data encryption, user authentication, and access control.

## Technologies Used

- **Frontend:** HTML, CSS, JavaScript, Bootstrap
- **Backend:** Django, Flask, Python, MySQL
- **Deep Learning:** Transformers, Gemma-7b, HuggingFace, TensorFlow, PyTorch
- **Tools:** Gradio, VSCode, GitHub, Colab

### Hardware Requirements

- Windows Operating System
- 256 MB RAM
- 10 GB Hard Disk

### Software Requirements

- Django
- MySQL
- HTML, CSS, JavaScript

## Installation

1. Clone the repository:
   ```
   git clone https://github.com/Pathakdarshan12/iTAS.git
   ```

2. Navigate into the project directory:
   ```
   cd iTAS
   ```

3. Install dependencies:
   ```
   pip install -r requirements.txt
   ```

## Usage

1. Set up the database:
   - Create a MySQL database and configure settings in `settings.py`.

2. Run migrations:
   ```
   python manage.py makemigrations
   python manage.py migrate
   ```

3. Start the Django development server:
   ```
   python manage.py runserver
   ```

4. Access the application at `http://localhost:8000` in your web browser.

## Folder Structure

```
intelligent-talent-acquisition/
│
├── README.md
├── requirements.txt
├── manage.py
├── yourapp/
│   ├── __init__.py
│   ├── settings.py
│   ├── urls.py
│   └── ...
└── home/
    ├── migrations/
    ├── templates/
    ├── views.py
    ├── models.py
    └── ...
```

## Database Design

The database schema includes tables for storing candidate information, job requirements, interview schedules, etc. Refer to `home/models.py` for detailed database models.

## Contributing

Contributions are welcome! Please fork the repository and submit a pull request with your improvements.

## Authors

- **Mr. Darshan S. Pathak** - [GitHub](https://github.com/Pathakdarshan12)
                            - [LinkedIn](https://www.linkedin.com/in/pathakdarshan12/)
                            - [Gmail](mailto:pathakdarshan@gmail.com)


## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).

