# Roadmap: Matheus Apple Med Dev Suite

**Document Version:** 1.0  
**Date:** 2025-09-18

## 1. Vision & Core Principles

The **Matheus Apple Med Dev Suite** aims to be a comprehensive, highly-integrated, and opinionated toolkit for medical software developers, researchers, and clinicians operating within the Apple ecosystem. It bridges the gap between local developer productivity on macOS and the power of modern, cloud-native applications and large language models.

### Core Principles

- **Apple-First, not Apple-Only:** Design for a best-in-class experience on macOS, leveraging its unique features (SwiftUI, Shortcuts, Hammerspoon, Keychain), while ensuring core components (services, CLI tools) remain portable to Linux environments.
- **Developer Experience (DX) is Paramount:** Provide powerful, intuitive, and fast tools (`gemx.sh`, `medcli`, FZF menus) that reduce friction and accelerate development and research cycles.
- **Security & Privacy by Design:** Emphasize secure practices for handling credentials (SSH keys, API tokens) and health data. Promote patterns that separate sensitive data from open-source tooling.
- **Cloud-Native & Deployable:** All services are designed to be containerized and deployed on Kubernetes, with production-grade Helm charts and Terraform infrastructure-as-code.
- **Modular & Extensible:** The suite is composed of independent modules (`ssh_kit`, `loinc_web`, `gemini_megapack`) that can be used together or separately. A plugin and automation architecture allows for easy extension.
- **Clinically-Grounded AI:** Leverage the power of Gemini models not just for generic tasks, but for specific, high-value clinical workflows through structured automations and integrations with medical terminologies.

---

## 2. Current State (Q3 2025)

The suite is currently composed of three mature, interconnected pillars.

### Pillar 1: `macos/ssh_kit` (The Local Experience)
A robust toolkit for supercharging the local macOS environment.
- **SSH & Security:** Comprehensive scripts for SSH key generation (Ed25519, FIDO2), server hardening, and seamless Keychain integration.
- **Networking:** Scripts for integrating with **Tailscale** and **ZeroTier**. Automated SSH tunneling via `launchd` and an app-aware `Hammerspoon` configuration.
- **`medcli`**: A powerful Python CLI for interacting with medical APIs (FHIR, OpenFDA, RxNorm, CTGov) and bridging data to/from **Obsidian**.
- **UI/UX**: Includes `sshx` (an FZF-based SSH launcher), and simple **SwiftUI** apps (`MedPanel`, `MenuBarTunnels`) for basic GUI interactions.

### Pillar 2: `services/loinc_web` (Core Terminology Service)
A deployable microservice for the LOINC medical terminology.
- **Technology**: A **FastAPI** backend with a **SQLite** database, using FTS5 for fast searching. The frontend is a lightweight, server-rendered UI using **HTMX**.
- **Deployment**: Fully containerized with Docker and includes a production-ready **Helm chart** for Kubernetes deployment.

### Pillar 3: `k8s/gemini_megapack` (The AI Core)
A sophisticated framework for leveraging Google's Gemini models in a clinical context.
- **`gemx.sh` Wrapper**: A powerful shell-based command center that manages configuration, profiles, prompt templates, and execution. It features FZF-powered menus for a fluid user experience and enforces the use of `gemini-2.5-pro`.
- **Clinical Automations**: A set of pre-defined YAML files that encode clinical protocols (e.g., Sepsis Bundle, HDA Triage, AKI Management), which can be executed by `gemx.sh` to generate structured, actionable guidance.
- **Deployment**:
    - **Local**: `docker-compose` setup with support for Caddy and Traefik.
    - **Cloud**: Production-grade **Helm chart** and **Terraform** scripts for provisioning a GKE Autopilot cluster and deploying the application with Ingress, managed certificates, and OAuth2 authentication.
- **Web UI**: A basic FastAPI web application that provides an API and a simple frontend for the `gemx.sh` generation and flow commands.

---

## 3. Future Roadmap

### 3.1. `macos/ssh_kit` & `medcli` (The Local Experience)

#### Short-Term (Q4 2025)
- **`medcli` API Expansion:**
    - Add a `snomed` command to browse SNOMED-CT concepts from the local `med-dicts.sqlite` database.
    - Add an `icd10` command for ICD-10-CM code lookups.
- **SwiftUI Enhancements:**
    - Refactor `MedPanel` to be more dynamic, allowing users to select the `medcli` command to run instead of having hardcoded buttons.
- **`sshx` Improvements:**
    - Add a preview window in the FZF selector that shows host details (tags, roles) from `inventory/hosts.yml`.
- **Obsidian Bridge V2:**
    - Add support for creating new notes based on templates directly from `medcli`.
    - Explore two-way sync for specific frontmatter fields.

#### Mid-Term (2026 H1)
- **`med-dicts.sqlite` V2:**
    - Enhance the dictionary import scripts to create cross-reference tables between terminologies (e.g., LOINC-to-SNOMED mappings where available).
- **Local RAG with `medcli`:**
    - Introduce a `med rag` command that uses the local `med-dicts.sqlite` and files in a specified knowledge base directory to provide context for a local LLM query.
- **Homebrew Packaging:**
    - Create a Homebrew formula to allow installation of `medcli` and its dependencies via `brew install medcli`.

#### Long-Term (2026 H2+)
- **Native `medcli` Exploration:**
    - Investigate rewriting parts of `medcli` in Swift to create a native macOS application with deeper system integration (e.g., native GUI, background services).
- **On-Device PHI Handling:**
    - Research patterns for handling sensitive (PHI) data securely on-device, potentially using the Secure Enclave for key storage and data encryption.

### 3.2. Core Services (`loinc_web`, etc.)

#### Short-Term (Q4 2025)
- **`loinc-web` Semantic Search:**
    - Add an optional API endpoint (`/api/loinc/semantic-search`) that uses a lightweight sentence-transformer model within the container to find semantically similar LOINC terms.
- **UI/UX Improvements:**
    - Enhance the HTMX search input with an autocomplete dropdown that suggests terms as the user types, powered by the `/api/loinc/suggest` endpoint.

#### Mid-Term (2026 H1)
- **New Service: `snomed-web`:**
    - Create a new `snomed-web` service following the same architecture as `loinc_web` to provide a searchable interface for SNOMED-CT (respecting its licensing terms).
- **Unified Authentication:**
    - Add an authentication layer (e.g., using the same OAuth pattern as `gemini_megapack`) to the `loinc-web` and future `snomed-web` services to restrict access.

### 3.3. `k8s/gemini_megapack` (The AI Core)

#### Short-Term (Q4 2025)
- **Full Gemini 2.5 Pro Integration:**
    - Refactor the `gemx.sh` wrapper and clinical automations to fully utilize new capabilities of the Gemini 2.5 Pro model, such as advanced tool use and multi-step reasoning.
- **Web UI V2 (Project "Stethoscope"):**
    - Initiate a rebuild of the web UI from a simple static page into a more interactive Single Page Application (SPA) using **React** or **Vue**.
    - The new UI will support full chat sessions, display structured outputs (tables, checklists) from automations, and manage conversation history.
- **Plugin System V2:**
    - Formalize the `plugins.d` system. Plugins will have a manifest file to declare their commands, arguments, and dependencies, allowing `gemx.sh` to dynamically register them.

#### Mid-Term (2026 H1)
- **Flow Engine V2:**
    - Evolve `flow-run.sh` into a more capable workflow engine.
    - Add support for conditional logic (`if/else`), loops (`for`), and passing structured JSON data between steps.
- **Enhanced Multi-modality:**
    - Expand `gemx.sh` to handle more than just static images. Add support for audio input (transcription via a local model or API) and video analysis (if supported by the Gemini API).
- **Integrated Observability:**
    - Integrate the `vector-sidecar` and `fluentbit-sidecar` configurations directly into the main `gemx` Helm chart as optional, enabled sub-charts for easier log shipping to Loki or Elasticsearch.

#### Long-Term (2026 H2+)
- **Autonomous Clinical Agents:**
    - Evolve the YAML automations into a framework for building autonomous agents. These agents could perform multi-step clinical tasks (e.g., "Work up this patient for sepsis"), use tools (like the `medcli` APIs to fetch lab results), and maintain state across interactions.
- **Federated Fine-Tuning Research:**
    - Begin research into privacy-preserving fine-tuning of models on local, anonymized clinical datasets. This would involve exploring techniques like Federated Learning to improve model performance on specific institutional data without centralizing it.

### 3.4. Cross-Cutting Concerns

- **Documentation:**
    - **Q4 2025:** Improve the README in each subdirectory with more detailed usage instructions and examples.
    - **2026 H1:** Set up a static site generator (e.g., MkDocs, Docusaurus) to build a unified documentation portal for the entire suite.
- **Testing:**
    - **Q4 2025:** Add a `tests/` directory to `medcli` and `gemini_megapack` with initial unit and integration tests.
    - **2026 H1:** Achieve >70% test coverage for all Python code in the project. Add shell-based integration tests for `gemx.sh`.
- **CI/CD:**
    - **Q4 2025:** Expand the existing GitHub Actions workflows to run all new tests and lint checks on every commit.
    - **2026 H1:** Create a staging environment on GKE. Set up a GitHub Actions workflow to automatically deploy the `main` branch to this staging environment for end-to-end testing.

---

## 4. Próximos Passos: Integração da Base de Conhecimento

A recente adição de uma biblioteca de referência médica (manuais de emergência em PDF e o arquivo `drogas.md`) abre novas e importantes frentes de desenvolvimento para a suite. Os próximos passos se concentrarão em integrar este conhecimento diretamente nas ferramentas existentes:

### 4.1. Alimentar o Plugin de RAG (Retrieval-Augmented Generation)
- **Ação:** Indexar o conteúdo textual dos novos PDFs e do arquivo `drogas.md`.
- **Objetivo:** Permitir que o `gemx.sh rag` possa realizar buscas e extrair informações diretamente desta base de conhecimento. Isso transformará o RAG de um buscador de contexto genérico para uma ferramenta de consulta de referência médica, capaz de responder perguntas como "qual a dose de ataque de amiodarona na FV?" com base nos manuais.

### 4.2. Validar e Refinar as Automações Clínicas
- **Ação:** Realizar uma revisão cruzada dos protocolos de automação existentes (`sca_protocol.yaml`, `avc_protocol.yaml`, etc.) contra as diretrizes e tabelas presentes nos PDFs.
- **Objetivo:** Aumentar a robustez e a precisão dos prompts, garantindo que as perguntas interativas e as seções de tratamento estejam alinhadas com as melhores práticas descritas na literatura adicionada. Isso inclui refinar doses, contraindicações e fluxos de decisão.

### 4.3. Expansão do Conteúdo Didático
- **Ação:** Usar as tabelas de medicamentos e os algoritmos dos PDFs como base para criar novos notebooks didáticos.
- **Objetivo:** Desenvolver notebooks focados em:
    - **`04_Calculo_de_Drogas_de_Emergencia.ipynb`**: Um guia interativo para calcular doses de drogas vasoativas e outras medicações de emergência.
    - **`05_Interpretacao_de_Algoritmos_ACLS.ipynb`**: Um notebook que disseca os algoritmos de parada cardiorrespiratória presentes nos manuais.