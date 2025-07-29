# Changelog

All notable changes to this project will be documented in this file.

This project adheres to [Semantic Versioning](https://semver.org).

---

## [0.1.0] - 2025-01-29

### Added

- ✨ **Smart Config Discovery** - Auto-detects `.env_check.yml` (root) or `config/env_check.yml` (Rails)
- ✨ **Enhanced Validator Suite** - Comprehensive validation types:
  - `boolean` - Validates boolean values including `true/false`, `1/0`, `yes/no`, `on/off` 
  - `integer` - Validates integer numbers (including negative)
  - `float` - Validates floating point numbers
  - `string` - Validates any string value
  - `url` - Validates URLs starting with `http://` or `https://`
  - `email` - Validates email format
  - `port` - Validates port numbers (1-65535)
  - `path` - Validates file/directory paths
  - `json` - Validates JSON strings
- 🎯 **Result Object** - `EnvCheck.verify` returns a `Result` object with `success?`, `errors`, `warnings`, and `valid_vars` properties
- � **Enhanced CLI** with `check`, `version`, and `init` commands with professional UX
- 🏗️ **Environment-specific Configuration** - Support for development, test, production sections
- 🧪 **Comprehensive Test Suite** - 21 test cases covering all functionality
- � **Flexible YAML Configuration** - Supports both hash and array formats for optional variables
- 📝 **Rake Task Integration** - `rake env:check` for CI usage
- 📖 **Comprehensive Documentation** and examples

### Features

- **Smart Configuration Discovery**: Prioritizes `.env_check.yml` (simple projects) over `config/env_check.yml` (Rails)
- **Type Validation**: Robust validation with helpful error messages for all supported types
- **Environment-specific Settings**: Different validation rules for development, test, and production
- **Flexible YAML Formats**: Supports both `optional: { VAR: type }` and `optional: [{ VAR: type }]` formats
- **CLI Tools**: Professional command-line interface for initialization and validation
- **Rails Integration**: Seamless integration with Rails 7.1+ applications
- **Dotenv Support**: Automatic `.env` file loading when available
- **Null/Empty Handling**: Graceful handling of missing and empty environment variables

### Technical Implementation

- **Modular Architecture**: Separate `Config`, `Validators`, and `Result` classes
- **Error Handling**: Structured result objects with detailed error reporting
- **Code Quality**: Zero RuboCop offenses, comprehensive test coverage
- **Thread-safe**: Safe for concurrent usage
- **Framework Agnostic**: Works with any Ruby application, optimized for Rails

### Compatibility

- **Ruby**: 3.0+
- **Rails**: 7.1+ through 8.0+ (framework-agnostic design)
- **CI/CD**: Comprehensive GitHub Actions integration

---
