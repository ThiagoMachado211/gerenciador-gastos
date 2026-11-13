from django.urls import path
from django.http import HttpResponse
from django.shortcuts import redirect
from django.contrib.auth import views as auth
from backend.finance import views

urlpatterns = [
    path('', views.home, name='home'),
    path('up', lambda request: HttpResponse('ok', content_type='text/plain')),
    path('public/planos-pagos', views.pricing, name='pricing'),
    path('users/sign_in', views.sign_in, name='login'),
    path('users/sign_up', views.register, name='register'),
    path('users/sign_out', views.sign_out, name='logout'),
    path('users/edit', views.profile, name='profile'),
    path('users/password/change', views.password_change, name='password_change'),
    path('users/delete', views.delete_account, name='delete_account'),
    path('users/password/new', views.LimitedPasswordResetView.as_view(), name='password_reset'),
    path('users/password/sent', auth.PasswordResetDoneView.as_view(template_name='registration/password_reset_done.html'), name='password_reset_done'),
    path('users/password/reset/<uidb64>/<token>', auth.PasswordResetConfirmView.as_view(template_name='form.html', extra_context={'title': 'Nova senha'}), name='password_reset_confirm'),
    path('users/password/done', auth.PasswordResetCompleteView.as_view(template_name='registration/password_reset_complete.html'), name='password_reset_complete'),
    path('users/dashboard', views.dashboard, name='dashboard'),
    path('users/analytics', lambda request: redirect('dashboard')),
    path('users/subscription', views.subscription, name='subscription'),
    path('admin', views.admin_dashboard, name='admin'),
    path('admin/users', views.admin_dashboard, name='admin_users'),
]
for resource in views.RESOURCES:
    urlpatterns += [
        path(f'users/{resource}', views.resource_list, {'resource': resource}, name=resource),
        path(f'users/{resource}/new', views.resource_form, {'resource': resource}),
        path(f'users/{resource}/<int:pk>/edit', views.resource_form, {'resource': resource}),
        path(f'users/{resource}/<int:pk>/delete', views.resource_delete, {'resource': resource}),
    ]
