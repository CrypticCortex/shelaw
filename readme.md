## SheLaw: Chat. Learn. Utilize.

**Problem Statement**: Women often face legal challenges and barriers that can be difficult to speak up about or seek help for. SheLaw aims to provide a safe, supportive, and informative platform.

**Overview**

It (shelaw) is a comprehensive platform designed to provide legal advice to women by crunching ~10 (will be expanded in future) legal documents This project comprises two core components:

1. **Backend:** A scalable API built on the **FastAPI**.
2. **Frontend:** A mobile application developed using **Flutter**.

**Project Structure**

- **backend:** This directory houses the core logic of the SheLaw platform, including:

  - **API Endpoints:** FastAPI-powered endpoints for handling user requests, processing information, and generating responses.
  - **RAG Pipeline:** Implementation of the Retrieval Augmented Generation (RAG) pipeline, integrating with a knowledge base and utilizing advanced Large Language Models (LLMs) to provide insightful and context-aware responses. Utilized chromadb for semantic search.
  - **Data Handling:** Modules for data management, including user authentication, data storage, and retrieval.
  - **Utility Functions:** Helper functions for tasks such as data preprocessing, API integrations, and error handling.

- **frontend:** This directory contains the source code for the SheLaw mobile application, including:
  - **User Interface (UI):** Implementation of the user interface with Flutter, ensuring a visually appealing and user-friendly experience.
  - **User Interactions:** Handling user inputs, managing user sessions, and displaying information effectively.
  - **API Integration:** Integration with the backend API to facilitate communication and data exchange.

**Key Technologies**

- **Backend:**

  - **FastAPI:** A high-performance web framework for building modern APIs in Python.
  - **Langchain:** A library for all gen-ai tasks, including RAG, calling LLMs, chaining them & other useful functions.

- **Frontend:**
  - **Flutter:** A cross-platform framework for building natively compiled applications from a single codebase.
  - **Dart:** A modern, object-oriented programming language designed for client-side development in Flutter.

**Project Goals**

- **Provide Support to Women:** Provide women with access to valuable information, personalized guidance, and a supportive community.
- **Develop Cutting-Edge AI:** Utilize advanced AI techniques, such as RAG and LLMs, to create a sophisticated and effective conversational AI.
- **Build a User-Centric Platform:** Design and develop a user-friendly and accessible platform that meets the needs and expectations of diverse users.

**Future Directions**

- **Expanding Functionality:** Integrate new features such as voice interaction, multilingual support.
- **Community Building:** Fostering a vibrant community around SheLaw, enabling users to connect, share experiences, and provide mutual support.

## Tech Stack

<p align="center" style="display: flex; justify-content: center; align-items: center; gap: 10px;">
  <!-- Badges -->
  <a href="https://supabase.com">
    <img src="https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white" alt="Supabase" height="40">
  </a>
  <a href="https://flutter.dev">
    <img src="https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white" alt="Flutter" height="40">
  </a>
  <a href="https://dart.dev">
    <img src="https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" height="40">
  </a>
  <a href="https://langchain.com">
    <img src="https://img.shields.io/badge/Langchain-%230175C2.svg?style=for-the-badge&logo=langchain&logoColor=white" alt="Langchain" height="40">
  </a>
  <!-- Chroma Logo -->
  <a href="https://trychroma.com">
    <img src="https://user-images.githubusercontent.com/891664/227103090-6624bf7d-9524-4e05-9d2c-c28d5d451481.png" alt="Chroma logo" height="40">
  </a>
</p>
