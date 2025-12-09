from django.contrib import admin

from django.contrib import admin
from .models import Resume


@admin.register(Resume)
class ResumeAdmin(admin.ModelAdmin):
    list_display = ['candidate_name', 'email', 'ats_score', 'score_category',
                    'years_of_experience', 'total_skills_count', 'scanned_at']
    list_filter = ['scanned_at', 'has_quantifiable_achievements', 'degrees']
    search_fields = ['candidate_name', 'email', 'phone', 'file_name']
    readonly_fields = ['uploaded_at', 'scanned_at', 'full_scan_data']

    fieldsets = (
        ('File Information', {
            'fields': ('file_name', 'file_path', 'uploaded_at', 'scanned_at')
        }),
        ('ATS Score', {
            'fields': ('ats_score',)
        }),
        ('Contact Information', {
            'fields': ('candidate_name', 'email', 'phone', 'linkedin_url',
                       'github_url', 'location')
        }),
        ('Education', {
            'fields': ('degrees', 'graduation_years', 'gpa')
        }),
        ('Experience', {
            'fields': ('years_of_experience', 'total_jobs')
        }),
        ('Skills', {
            'fields': ('technical_skills', 'soft_skills', 'skills_by_category',
                       'total_skills_count')
        }),
        ('Structure', {
            'fields': ('sections_detected', 'has_summary', 'has_experience_section',
                       'has_education_section', 'has_skills_section')
        }),
        ('Achievements', {
            'fields': ('has_quantifiable_achievements', 'achievement_count',
                       'top_keywords')
        }),
        ('Document Stats', {
            'fields': ('word_count', 'character_count')
        }),
        ('Full Data', {
            'fields': ('full_scan_data', 'notes'),
            'classes': ('collapse',)
        }),
    )
