"""
Django Management Command for ATS Resume Scanner

File structure:
your_project/
    home/
        management/
            commands/
                ats_resume_scan.py  <- This file

Usage:
    python manage.py ats_resume_scan path/to/resume.pdf
"""
from datetime import timezone, datetime

import PyPDF2
from django.core.management.base import BaseCommand, CommandError
import re
import os
from collections import Counter

class IndustryATSScanner:
    """Professional ATS Resume Scanner"""

    def __init__(self):
        self.technical_skills = {
            'programming': ['python', 'java', 'javascript', 'typescript', 'c', 'c++', 'c#', 'ruby', 'php', 'swift', 'kotlin', 'go', 'rust', 'scala', 'r', 'matlab', 'perl', 'dart', 'bash', 'powershell', 'objective-c'],
            'web_frontend': ['react', 'react.js', 'angular', 'vue', 'vue.js', 'svelte', 'next.js', 'nuxt.js', 'html', 'html5', 'css', 'css3', 'sass', 'scss', 'jquery', 'bootstrap', 'tailwind', 'material-ui', 'redux', 'webpack', 'vite'],
            'web_backend': ['node.js', 'express', 'django', 'flask', 'spring', 'spring boot', 'asp.net', 'asp.net core', 'rails', 'ruby on rails', 'laravel', 'fastapi', 'nest.js', 'hapi.js', 'koa.js', 'graphql', 'rest api'],
            'databases': ['sql', 'mysql', 'postgresql', 'sqlite', 'mongodb', 'redis','elasticsearch', 'oracle', 'sql server', 'dynamodb', 'cassandra','neo4j', 'couchdb', 'firebase', 'snowflake', 'redshift', 'bigquery'],
            'cloud': ['aws', 'amazon web services', 'azure', 'gcp', 'google cloud', 'ec2', 's3', 'lambda', 'cloudfront', 'ecs', 'eks', 'cloud run', 'app engine', 'azure devops', 'firebase', 'heroku'],

            'devops': [
                'docker', 'kubernetes', 'k8s', 'jenkins', 'gitlab', 'github actions',
                'ci/cd', 'terraform', 'ansible', 'puppet', 'chef', 'prometheus',
                'grafana', 'helm', 'istio', 'nginx', 'apache'
            ],

            'data_science': [
                'machine learning', 'deep learning', 'tensorflow', 'pytorch',
                'scikit-learn', 'pandas', 'numpy', 'scipy', 'matplotlib', 'seaborn',
                'data analysis', 'nlp', 'computer vision', 'opencv', 'keras',
                'huggingface transformers'
            ],

            'mobile': [
                'android', 'ios', 'flutter', 'react native', 'swiftui', 'kotlin',
                'xamarin'
            ],

            'big_data': [
                'hadoop', 'spark', 'pyspark', 'kafka', 'hive', 'airflow', 'beam',
                'databricks'
            ],

            'testing': [
                'selenium', 'jest', 'mocha', 'chai', 'junit', 'pytest', 'cypress',
                'postman', 'k6'
            ],

            'tools': [
                'git', 'jira', 'bitbucket', 'vs code', 'intellij', 'postman',
                'figma', 'linux', 'ubuntu'
            ]
        }

        self.all_skills = []
        for skills in self.technical_skills.values():
            self.all_skills.extend(skills)

        self.soft_skills = ['leadership', 'communication', 'teamwork', 'problem solving',
                            'critical thinking', 'analytical', 'collaborative']

        self.section_headers = [
            'experience', 'work experience', 'professional experience',
            'education', 'academic background',
            'skills', 'technical skills', 'core competencies',
            'projects', 'certifications', 'summary', 'objective', 'additional information',
        ]

    def extract_text_from_pdf(self, file_path):
        if not PyPDF2:
            raise ImportError("PyPDF2 not installed. Run: pip install PyPDF2")
        text = ""
        try:
            with open(file_path, 'rb') as file:
                pdf_reader = PyPDF2.PdfReader(file)
                for page in pdf_reader.pages:
                    text += page.extract_text() + "\n"
        except Exception as e:
            raise Exception(f"Error reading PDF: {e}")
        return text

    def extract_text_from_txt(self, file_path):
        try:
            with open(file_path, 'r', encoding='utf-8') as file:
                return file.read()
        except Exception as e:
            raise Exception(f"Error reading TXT: {e}")

    def read_resume(self, file_path):
        if not os.path.exists(file_path):
            raise FileNotFoundError(f"File not found: {file_path}")
        ext = os.path.splitext(file_path)[1].lower()
        if ext == '.pdf':
            return self.extract_text_from_pdf(file_path)
        elif ext == '.txt':
            return self.extract_text_from_txt(file_path)
        else:
            raise ValueError(f"Unsupported format: {ext}")

    def extract_contact_info(self, text):
        email_pattern = r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'
        emails = re.findall(email_pattern, text)

        phone_pattern = r'(?:\+?\d{1,3}[-.\s]?)?\d{10}'
        phones = re.findall(phone_pattern, text)

        linkedin = re.findall(r'linkedin\.com/in/[\w-]+', text.lower())
        github = re.findall(r'github\.com/[\w-]+', text.lower())

        lines = [line.strip() for line in text.split('\n') if line.strip()]
        name = lines[0] if lines else "Not found"

        location = re.findall(r'[A-Z][a-z]+,\s*[A-Z]{2}', text)

        return {
            'name': name,
            'emails': list(set(emails)),
            'phones': list(set([p if isinstance(p, str) else p[0] for p in phones])),
            'linkedin': linkedin,
            'github': github,
            'location': location[0] if location else None
        }

    def detect_sections(self, text):
        detected = {}
        lines = text.split('\n')
        current_section = None
        content = []

        for line in lines:
            line_lower = line.lower().strip()
            is_header = False

            for header in self.section_headers:
                if header in line_lower and len(line_lower) < 50:
                    if current_section:
                        detected[current_section] = '\n'.join(content)
                    current_section = header
                    content = []
                    is_header = True
                    break

            if not is_header and current_section:
                content.append(line)

        if current_section:
            detected[current_section] = '\n'.join(content)

        return detected

    def extract_education(self, text):
        degrees = {
            'Bachelor': r"bachelor[']?s?|b\.?s\.?|b\.?a\.?",
            'Master': r"master[']?s?|m\.?s\.?|m\.?a\.?|mba",
            'PhD': r"ph\.?d\.?|doctorate",
            'Associate': r"associate[']?s?|a\.?s\.?"
        }

        found = []
        text_lower = text.lower()

        for degree, pattern in degrees.items():
            if re.search(pattern, text_lower):
                found.append(degree)

        years = re.findall(r'\b(19|20)\d{2}\b', text)
        gpa_match = re.findall(r'gpa[:\s]+(\d\.\d+)', text.lower())

        return {
            'degrees': list(set(found)),
            'years': list(set(years)),
            'gpa': gpa_match[0] if gpa_match else None
        }

    def extract_experience(self, text):
        exp_patterns = [
            r'(\d+)\+?\s*years?\s*(?:of\s*)?experience',
            r'experience\s*(?:of\s*)?(\d+)\+?\s*years?'
        ]

        years = []
        for pattern in exp_patterns:
            matches = re.findall(pattern, text.lower())
            years.extend([int(y) for y in matches])

        date_ranges = re.findall(
            r'((?:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec'
            r'|january|february|march|april|may|june|july|august|'
            r'september|october|november|december)\.?\s*\d{4}'
            r'|(?:19|20)\d{2})'
            r'\s*(?:-|–|—|to)\s*'
            r'((?:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec'
            r'|january|february|march|april|may|june|july|august|'
            r'september|october|november|december)\.?\s*\d{4}'
            r'|(?:19|20)\d{2}|present|current)',
            text.lower()
        )

        return {
            'years_mentioned': max(years) if years else None,
            'date_ranges': len(date_ranges)
        }

    def extract_skills(self, text):
        text_lower = text.lower()
        technical = []
        soft = []
        categories = {}

        for category, skills in self.technical_skills.items():
            cat_skills = []
            for skill in skills:
                pattern = r'\b' + re.escape(skill) + r's?\b'
                if re.search(pattern, text_lower):
                    technical.append(skill)
                    cat_skills.append(skill)
            if cat_skills:
                categories[category] = cat_skills

        for skill in self.soft_skills:
            if re.search(r'\b' + re.escape(skill) + r'\b', text_lower):
                soft.append(skill)

        return {
            'technical': list(set(technical)),
            'soft': list(set(soft)),
            'by_category': categories,
            'total': len(set(technical)) + len(set(soft))
        }

    def check_achievements(self, text):
        patterns = [
            r'\d+%',
            r'\$\d+',
            r'increased.*\d+',
            r'decreased.*\d+',
            r'improved.*\d+',
            r'reduced.*\d+'
        ]

        achievements = []
        for pattern in patterns:
            achievements.extend(re.findall(pattern, text.lower()))

        return {
            'has_achievements': len(achievements) > 0,
            'count': len(achievements),
            'examples': achievements[:5]
        }

    def calculate_keywords(self, text, top_n=20):
        words = re.findall(r'\b[a-zA-Z+#.-]{3,}\b', text.lower())
        stop_words = {'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to',
                      'for', 'of', 'with', 'by', 'from', 'as', 'is', 'was', 'are'}
        filtered = [w for w in words if w not in stop_words]
        freq = Counter(filtered)
        return dict(freq.most_common(top_n))

    def scan_resume(self, file_path):
        resume_text = self.read_resume(file_path)

        if not resume_text or len(resume_text) < 100:
            return {"error": "Insufficient text extracted"}

        contact = self.extract_contact_info(resume_text)
        sections = self.detect_sections(resume_text)
        education = self.extract_education(resume_text)
        experience = self.extract_experience(resume_text)
        skills = self.extract_skills(resume_text)
        achievements = self.check_achievements(resume_text)
        keywords = self.calculate_keywords(resume_text)

        # Calculate score
        score = 0
        score += 15 if (contact['emails'] and contact['phones']) else 5
        score += min(20, len(sections) * 4)
        score += 10 if education['degrees'] else 5
        score += min(15, (experience['years_mentioned'] or 0) * 2)
        score += min(25, len(skills['technical']) * 2)
        score += 10 if achievements['has_achievements'] else 0


        return {
            'score': round(min(100, score), 1),
            'contact': contact,
            'sections': list(sections.keys()),
            'education': education,
            'experience': experience,
            'skills': skills,
            'achievements': achievements,
            'keywords': keywords,
            'word_count': len(resume_text.split()),
            'character_count': len(resume_text)
        }


class Command(BaseCommand):
    help = 'Scan resume with ATS and store results in database'

    def add_arguments(self, parser):
        parser.add_argument('file_path', type=str, help='Path to resume file')
        parser.add_argument('--detailed', action='store_true', help='Show detailed analysis')
        parser.add_argument('--no-save', action='store_true', help='Don\'t save to database')

    def handle(self, *args, **options):
        file_path = options['file_path']
        detailed = options.get('detailed', False)
        no_save = options.get('no_save', False)

        self.stdout.write(self.style.SUCCESS('\n' + '=' * 70))
        self.stdout.write(self.style.SUCCESS('ATS RESUME SCANNER - WITH DATABASE STORAGE'))
        self.stdout.write(self.style.SUCCESS('=' * 70 + '\n'))

        try:
            # Import model here to avoid circular imports
            from home.models import Resume

            scanner = IndustryATSScanner()
            results = scanner.scan_resume(file_path)

            if 'error' in results:
                raise CommandError(results['error'])

            # Save to database
            if not no_save:
                resume_obj = Resume.objects.create(
                    # File info
                    file_name=os.path.basename(file_path),
                    file_path=file_path,
                    scanned_at=datetime.now(),

                    # ATS Score
                    ats_score=results['score'],

                    # Contact
                    candidate_name=results['contact']['name'],
                    email=results['contact']['emails'][0] if results['contact']['emails'] else None,
                    phone=results['contact']['phones'][0] if results['contact']['phones'] else None,
                    linkedin_url=f"https://{results['contact']['linkedin'][0]}" if results['contact'][
                        'linkedin'] else None,
                    github_url=f"https://{results['contact']['github'][0]}" if results['contact']['github'] else None,
                    location=results['contact']['location'],

                    # Education
                    degrees=results['education']['degrees'],
                    graduation_years=results['education']['years'],
                    gpa=results['education']['gpa'],

                    # Experience
                    years_of_experience=results['experience']['years_mentioned'],
                    total_jobs=results['experience']['date_ranges'],

                    # Skills
                    technical_skills=results['skills']['technical'],
                    soft_skills=results['skills']['soft'],
                    skills_by_category=results['skills']['by_category'],
                    total_skills_count=results['skills']['total'],

                    # Sections
                    sections_detected=results['sections'],
                    has_summary='summary' in results['sections'] or 'objective' in results['sections'],
                    has_experience_section='experience' in results['sections'] or 'work experience' in results[
                        'sections'],
                    has_education_section='education' in results['sections'],
                    has_skills_section='skills' in results['sections'] or 'technical skills' in results['sections'],

                    # Achievements
                    has_quantifiable_achievements=results['achievements']['has_achievements'],
                    achievement_count=results['achievements']['count'],
                    top_keywords=results['keywords'],

                    # Stats
                    word_count=results['word_count'],
                    character_count=results['character_count'],

                    # Full data
                    full_scan_data=results
                )

                self.stdout.write(self.style.SUCCESS(f'\n✅ Resume saved to database (ID: {resume_obj.id})'))

            # Display results
            score = results['score']
            self.stdout.write(f"\n{'OVERALL ATS SCORE':=^70}")

            if score >= 80:
                self.stdout.write(self.style.SUCCESS(f"\n🎯 SCORE: {score}/100"))
                self.stdout.write(self.style.SUCCESS("✅ EXCELLENT - Highly ATS-compatible\n"))
            elif score >= 60:
                self.stdout.write(self.style.WARNING(f"\n🎯 SCORE: {score}/100"))
                self.stdout.write(self.style.WARNING("⚠️  GOOD - ATS-compatible with improvements\n"))
            else:
                self.stdout.write(self.style.ERROR(f"\n🎯 SCORE: {score}/100"))
                self.stdout.write(self.style.ERROR("❌ NEEDS WORK - Requires optimization\n"))

            # Contact Info
            self.stdout.write(f"\n{'CONTACT INFORMATION':-^70}")
            contact = results['contact']
            self.stdout.write(f"Name: {contact['name']}")

            if contact['emails']:
                self.stdout.write(self.style.SUCCESS(f"✓ Email: {', '.join(contact['emails'])}"))
            else:
                self.stdout.write(self.style.ERROR("✗ Email: NOT FOUND"))

            if contact['phones']:
                self.stdout.write(self.style.SUCCESS(f"✓ Phone: {', '.join(contact['phones'])}"))
            else:
                self.stdout.write(self.style.ERROR("✗ Phone: NOT FOUND"))

            # Skills Summary
            self.stdout.write(f"\n{'SKILLS SUMMARY':-^70}")
            skills = results['skills']
            self.stdout.write(f"Total Skills: {skills['total']}")
            self.stdout.write(f"Technical: {len(skills['technical'])}")
            if detailed:
                self.stdout.write(f"Skills: {', '.join(skills['technical'][:10])}")

            # Achievements
            self.stdout.write(f"\n{'ACHIEVEMENTS':-^70}")
            ach = results['achievements']
            if ach['has_achievements']:
                self.stdout.write(self.style.SUCCESS(f"✓ {ach['count']} quantifiable achievements"))
            else:
                self.stdout.write(self.style.WARNING("⚠️  No quantifiable achievements"))

            self.stdout.write(f"\n{'=' * 70}\n")

            if not no_save:
                self.stdout.write(self.style.SUCCESS(f"✅ Data stored in database"))
                self.stdout.write(f"   Access via Django admin or Resume.objects.get(id={resume_obj.id})\n")

        except ImportError as e:
            if 'Resume' in str(e):
                raise CommandError(
                    "Resume model not found. Please add the Resume model to home/models.py\n"
                    "See the model definition in the comments at the top of this file."
                )
            raise CommandError(f"Missing dependency: {e}")
        except Exception as e:
            raise CommandError(f"Error: {str(e)}")