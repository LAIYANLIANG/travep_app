#!/bin/bash

echo "🚀 Setting up dependencies for Google Antigravity..."

# Core Architecture
flutter pub add flutter_riverpod
flutter pub add riverpod_annotation
flutter pub add get_it
flutter pub add equatable
flutter pub add dartz
flutter pub add dio
flutter pub add intl

# Security & Features
flutter pub add envied
flutter pub add google_maps_flutter

# Dev Dependencies (Code Generation & Linting)
flutter pub add --dev riverpod_generator
flutter pub add --dev build_runner
flutter pub add --dev envied_generator
flutter pub add --dev custom_lint
flutter pub add --dev riverpod_lint

echo "✅ Dependencies installed successfully!"
echo "ℹ️  Don't forget to create your .env file locally."
