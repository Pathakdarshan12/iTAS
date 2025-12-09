from django.db import models
from django.contrib.postgres.fields import JSONField

class Jobs(models.Model):
    id = models.CharField(max_length=255, primary_key=True)
    site = models.CharField(max_length=255, null=True)
    job_url = models.CharField(max_length=1000, null=True)  # URLs can be long
    job_url_direct = models.CharField(max_length=1000, null=True)  # URLs can be long
    title = models.CharField(max_length=500, null=True)  # Job titles can be detailed
    company = models.CharField(max_length=255, null=True)
    location = models.CharField(max_length=255, null=True)
    date_posted = models.CharField(max_length=255, null=True)
    job_type = models.CharField(max_length=255, null=True)
    salary_source = models.CharField(max_length=255, null=True)
    interval = models.CharField(max_length=255, null=True)
    min_amount = models.CharField(max_length=255, null=True)
    max_amount = models.CharField(max_length=255, null=True)
    currency = models.CharField(max_length=255, null=True)
    is_remote = models.CharField(max_length=255, null=True)
    job_level = models.CharField(max_length=255, null=True)
    job_function = models.CharField(max_length=500, null=True)  # Can have multiple functions
    listing_type = models.CharField(max_length=255, null=True)
    emails = models.CharField(max_length=500, null=True)  # Multiple emails possible
    description = models.CharField(max_length=1000000, null=True)  # Job descriptions are long
    company_industry = models.CharField(max_length=255, null=True)
    company_url = models.CharField(max_length=1000, null=True)  # URLs can be long
    company_logo = models.CharField(max_length=1000, null=True)  # URLs can be long
    company_url_direct = models.CharField(max_length=1000, null=True)  # URLs can be long
    company_addresses = models.CharField(max_length=1000, null=True)  # Multiple addresses
    company_num_employees = models.CharField(max_length=255, null=True)
    company_revenue = models.CharField(max_length=255, null=True)
    company_description = models.CharField(max_length=5000, null=True)  # Company descriptions are long
    skills = models.CharField(max_length=2000, null=True)  # Multiple skills listed
    experience_range = models.CharField(max_length=255, null=True)
    company_rating = models.CharField(max_length=255, null=True)
    company_reviews_count = models.CharField(max_length=255, null=True)
    vacancy_count = models.CharField(max_length=255, null=True)
    work_from_home_type = models.CharField(max_length=255, null=True)
    jobs_scraped_at = models.CharField(max_length=255, null=True)
    batch_id = models.CharField(max_length=255, null=True)

    def __str__(self):
        return self.title or "Untitled Job"

    class Meta:
        verbose_name = "Job"
        verbose_name_plural = "Jobs"
        ordering = ['-jobs_scraped_at']

class Resume(models.Model):
    # Basic Info
    file_name = models.CharField(max_length=255)
    file_path = models.CharField(max_length=500, blank=True, null=True)
    uploaded_at = models.DateTimeField(auto_now_add=True)
    scanned_at = models.DateTimeField(auto_now=True)

    # ATS Score
    ats_score = models.FloatField(default=0.0)

    # Contact Information
    candidate_name = models.CharField(max_length=255, blank=True, null=True)
    email = models.EmailField(blank=True, null=True)
    phone = models.CharField(max_length=50, blank=True, null=True)
    linkedin_url = models.URLField(blank=True, null=True)
    github_url = models.URLField(blank=True, null=True)
    location = models.CharField(max_length=255, blank=True, null=True)

    # Education
    degrees = models.JSONField(default=list, blank=True)  # List of degrees
    graduation_years = models.JSONField(default=list, blank=True)
    gpa = models.CharField(max_length=10, blank=True, null=True)

    # Experience
    years_of_experience = models.IntegerField(default=0, null=True, blank=True)
    total_jobs = models.IntegerField(default=0)

    # Skills
    technical_skills = models.JSONField(default=list, blank=True)
    soft_skills = models.JSONField(default=list, blank=True)
    skills_by_category = models.JSONField(default=dict, blank=True)
    total_skills_count = models.IntegerField(default=0)

    # Sections & Structure
    sections_detected = models.JSONField(default=list, blank=True)
    has_summary = models.BooleanField(default=False)
    has_experience_section = models.BooleanField(default=False)
    has_education_section = models.BooleanField(default=False)
    has_skills_section = models.BooleanField(default=False)

    # Achievements & Keywords
    has_quantifiable_achievements = models.BooleanField(default=False)
    achievement_count = models.IntegerField(default=0)
    top_keywords = models.JSONField(default=dict, blank=True)

    # Document Stats
    word_count = models.IntegerField(default=0)
    character_count = models.IntegerField(default=0)

    # Full Scan Results (stores everything)
    full_scan_data = models.JSONField(default=dict, blank=True)

    # Metadata
    notes = models.TextField(blank=True, null=True)

    class Meta:
        ordering = ['-scanned_at']
        indexes = [
            models.Index(fields=['-ats_score']),
            models.Index(fields=['-scanned_at']),
            models.Index(fields=['email']),
        ]

    def __str__(self):
        return f"{self.candidate_name or 'Unknown'} - {self.file_name} (Score: {self.ats_score})"

    @property
    def score_category(self):
        if self.ats_score >= 80:
            return "Excellent"
        elif self.ats_score >= 60:
            return "Good"
        elif self.ats_score >= 40:
            return "Fair"
        else:
            return "Poor"
