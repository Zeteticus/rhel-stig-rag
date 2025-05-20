An AI-powered Retrieval-Augmented Generation system for RHEL Security Technical Implementation Guide (STIG) assistance, with primary focus on RHEL 9 and secondary support for RHEL 8.

Overview
The RHEL STIG RAG system combines advanced language models with retrieval-based techniques to provide intelligent guidance for Red Hat Enterprise Linux security compliance. By leveraging vector search and AI, the system can:

Answer natural language questions about RHEL security requirements
Provide specific implementation steps for STIG controls
Prioritize RHEL 9 guidance while supporting RHEL 8
Generate detailed compliance recommendations
Cross-reference related security controls

Key Features
Core Capabilities

Natural Language Interface: Ask security compliance questions in plain English
RHEL Version Awareness: Primary focus on RHEL 9 with RHEL 8 support
Intelligent Retrieval: Vector-based semantic search finds relevant controls
Contextual Understanding: Comprehends security requirements and their relationships
Actionable Guidance: Step-by-step implementation instructions

Technical Features

Vector Database: Efficient storage and retrieval of STIG controls
Embedding Models: Semantic understanding of security concepts
REST API: Full API for integration with other tools
Interactive Client: Easy-to-use command-line interface

Deployment Options

Ansible Deployment: Enterprise-grade automation
Podman Deployment: Secure, rootless container deployment
Docker Deployment: Traditional container support
Native Installation: Direct system installation

Architecture
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   STIG Sources  │───▶│ Vector Database │───▶│  Query Engine   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                       │
                                                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│     Client      │◀───│      API        │◀───│  Language Model │
└─────────────────┘    └─────────────────┘    └─────────────────┘
Installation Options
Choose the installation method that best fits your environment:
Option 1: Quick Start (Development)
bash# Clone the repository
git clone https://github.com/your-username/rhel-stig-rag.git
cd rhel-stig-rag

# Setup environment
chmod +x setup.sh
./setup.sh

# Start the server
python3 app/rhel_stig_rag.py
Option 2: Podman Deployment (Recommended for RHEL)
bash# Clone the repository
git clone https://github.com/your-username/rhel-stig-rag.git
cd rhel-stig-rag

# Deploy with Podman
chmod +x podman/deploy-podman.sh
./podman/deploy-podman.sh deploy

# Check status
./manage-stig-rag.sh status
Option 3: Ansible Deployment (Enterprise)
bash# Clone the repository
git clone https://github.com/your-username/rhel-stig-rag.git
cd rhel-stig-rag/ansible

# Configure inventory
cp inventory/hosts.example inventory/hosts
# Edit inventory/hosts with your server details

# Deploy with Ansible
ansible-playbook -i inventory/hosts site.yml
Option 4: Docker Deployment
bash# Clone the repository
git clone https://github.com/your-username/rhel-stig-rag.git
cd rhel-stig-rag

# Deploy with Docker Compose
docker-compose up -d
Quick Start Guide
1. Load STIG Data
bash# Load sample RHEL 9 data (primary)
python3 app/stig_client.py load stig_data/sample_rhel9_stig.json

# Load sample RHEL 8 data (secondary)
python3 app/stig_client.py load stig_data/sample_rhel8_stig.json

# Or download official STIGs
python3 app/stig_data_collector.py
2. Query the System
bash# Interactive mode
python3 app/stig_client.py interactive

# Command-line queries (RHEL 9 default)
python3 app/stig_client.py query "How do I verify GPG signatures?" 

# Version-specific queries
python3 app/stig_client.py query "How do I configure SELinux?" --rhel-version 9
python3 app/stig_client.py query "How do I set up secure boot?" --rhel-version 8

# Search by STIG ID
python3 app/stig_client.py search RHEL-09-211010
3. API Usage
bash# Query endpoint
curl -X POST "http://localhost:8000/query" \
  -H "Content-Type: application/json" \
  -d '{
    "question": "How do I verify package signatures?",
    "rhel_version": "9"
  }'

# Health check
curl http://localhost:8000/health
📖 Documentation
Detailed documentation is available in the docs/ directory:

Installation Guide: Complete installation instructions
Podman Deployment Guide: Podman-specific deployment guide
API Reference: REST API documentation
User Guide: Usage instructions and examples

Usage Examples
RHEL 9 Package Verification
Query: "How do I verify GPG signatures in RHEL 9?"

Response:
RHEL 9 requires GPG signature verification for all packages to ensure software integrity. 

To verify that GPG signature checking is properly configured:

1. Check the main DNF configuration:
   $ sudo grep gpgcheck /etc/dnf/dnf.conf
   
   The output should show: gpgcheck=1

2. Verify all repositories have GPG checking enabled:
   $ sudo grep -r gpgcheck /etc/yum.repos.d/
   
   All repositories should show: gpgcheck=1

3. If any repositories have gpgcheck=0, edit the corresponding file:
   $ sudo vi /etc/yum.repos.d/repository-file.repo
   
   Change the line to: gpgcheck=1

This implements STIG control RHEL-09-211010 (high severity) and RHEL-09-211015.
SELinux Configuration
Query: "What is the proper SELinux configuration for RHEL?"

Response:
RHEL requires SELinux to be enabled in enforcing mode. Here's how to properly configure it:

1. Check current SELinux status:
   $ getenforce
   
   This should return "Enforcing"

2. If not enforcing, check configuration:
   $ cat /etc/selinux/config
   
   Ensure SELINUX=enforcing

3. Set SELinux to enforcing immediately:
   $ sudo setenforce 1
   
4. Verify correct policy is set:
   $ sestatus | grep "Policy"
   
   Should show "targeted"

This implements RHEL-09-230010 and helps satisfy multiple other controls.

Note: In RHEL 8, the control ID is RHEL-08-020020 with similar requirements.
Advanced Configuration
Custom Language Models
The system can be configured to use different language models:
bash# In .env file
LLM_PROVIDER=openai
OPENAI_API_KEY=your_openai_api_key_here
OPENAI_MODEL=gpt-3.5-turbo

# Or for Anthropic Claude
LLM_PROVIDER=anthropic
ANTHROPIC_API_KEY=your_anthropic_api_key_here
ANTHROPIC_MODEL=claude-3-sonnet-20240229
Performance Tuning
bash# In .env file
CHUNK_SIZE=1500
CHUNK_OVERLAP=300
DEFAULT_SEARCH_RESULTS=10
ENABLE_CACHING=true
CACHE_TTL_SECONDS=3600
🤝 Contributing
Contributions are welcome! Please feel free to submit a Pull Request.

Fork the repository
Create your feature branch (git checkout -b feature/amazing-feature)
Commit your changes (git commit -m 'Add some amazing feature')
Push to the branch (git push origin feature/amazing-feature)
Open a Pull Request

 License
This project is licensed under the MIT License - see the LICENSE file for details.
 Acknowledgements

DISA for the STIG documentation
Red Hat for RHEL documentation
LangChain for RAG framework components
ChromaDB for vector database
Sentence Transformers for embeddings
FastAPI for API development
