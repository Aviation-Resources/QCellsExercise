# QCells Exercise — Aviation Resources Browser

A SwiftUI iOS/macOS app that browses, searches, and previews aviation PDF documents fetched from a GraphQL API backed by AWS S3.

---

## Features

- **Paginated document list** — infinite-scroll grid of aviation resource cards (offset-based, 3 items/page)
- **Adaptive layout** — single-column on compact devices, 4-column grid on iPad/Mac
- **Real-time search** — filters by document name or document number as you type
- **Sort controls** — sort the list by document name or document number
- **PDF viewer** — tap a card to download and open the PDF inline via PDFKit
- **Thumbnail caching** — thumbnails and PDFs are persisted to disk via SDWebImage; subsequent opens are instant
- **Error handling** — networking failures surface in-UI error states at both the list and card level

---

## Setup

### Requirements

| Tool | Version |
|------|---------|
| Xcode | 16+ |
| iOS Deployment Target | 17+ |
| macOS Deployment Target | 14+ |

### Steps

1. Clone the repository.
2. Open `QCellsExercise.xcodeproj` in Xcode.
3. Swift Package Manager will resolve dependencies automatically on first open (Apollo iOS, ApolloSQLite, SDWebImage).
4. Select a simulator or device and run (`⌘R`).

### API Keys

No API key is required to run the app. The GraphQL endpoint (`https://graphql.aviationresources.io/v1/graphql`) and the services API (`https://api.aviationresources.io`) are accessed without client-side credentials.

---

## Architecture

The project uses a **multi-module architecture** via Swift Package Manager, separating generated GraphQL types from the main application target.

```
QCellsExercise (main app target)
│
├── Networking/
│   ├── GraphQLNetworking.swift   # Apollo client wrapper; async/await bridge
│   ├── ServicesNetworking.swift  # REST client for presigned S3 URL generation
│   ├── NetworkingInterface.swift # Shared URLSession utilities
│   ├── Environment.swift         # Environment protocol + Production config
│   └── NetworkingError.swift     # Typed error enum
│
└── UserInterface/
    ├── ResourcesListView.swift   # List screen + ResourcesListViewModel (@Observable)
    ├── ResourceView.swift        # Card + download state machine + ResourceViewModel
    ├── PDFKitView.swift          # UIViewRepresentable/NSViewRepresentable PDFKit wrapper
    └── ImageLoadingView.swift    # Async thumbnail renderer

ResourcesGraphQL (local Swift Package — Apollo codegen output)
├── Schema types generated from graphqls/
└── DocumentsQuery + Resource fragment
```

### Pattern

MVVM using the Swift `@Observable` macro. ViewModels are scoped as `fileprivate` classes within their view files, keeping each feature self-contained. Business logic (pagination, filtering, sort) lives entirely in the ViewModel; Views are declarative and state-driven.

### Data Flow

```
View (.task) → ViewModel.loadSourceData()
             → GraphQLNetworking.fetch(DocumentsQuery)
             → Apollo ApolloClient (InMemoryNormalizedCache)
             → resourceQuery[] → Resource fragments appended to state

ResourceView (on tap) → ServicesNetworking.post(.presignedGET)
                      → S3 presigned URL → URLSession download
                      → SDImageCache (disk) → PDFDocument → PDFKitView
```

---

## Libraries

| Library | Source | Purpose |
|---------|--------|---------|
| [Apollo iOS](https://github.com/apollographql/apollo-ios) | SPM (remote) | GraphQL client with normalized in-memory cache |
| ApolloSQLite | SPM (remote, bundled with Apollo) | SQLite persistence layer for Apollo (available, not yet activated) |
| [SDWebImage](https://github.com/SDWebImage/SDWebImage) | SPM (remote) | Disk-based image/data caching for thumbnails and PDFs |
| ResourcesGraphQL | SPM (local) | Apollo codegen output — schema types and query models |

---

## AI Documentation

### Scope of Usage

I used two main AI tools, first Anthropics Claude where I created a cowork project pointed at this repository. Second, I used the built in tooling in Xcode where I
have OpenAI codex setup with an API Key. I used these tools in conjunction wiht each other to ask questions about the project (Claude) and then to implement features using Codex as it has the better context and tooling wiht the Xcode integration. Here are several things I explicilty used AI to help me with.

- **Understand Project Requirements** — I was not sure what was meant by "multimodal" architecture and Claude helped clarify (seperation of concerns and package manager)
- **De-bugging code generation issues** — I got some error messages when doing the GraphQL introspection and code generation. I used AI to suggest some fixes and it helped me itentify a version mismatch between the cli tool and the package version.
- **Cross-platform PDFViewer** — Once I had the iOS version of the PDF Viewer is was no problem for AI to give me the MacOS Version.
- **README starter** — I asked AI to give me a starter structure for this document so that I could focus on filling in the important parts.
- **UI Changes and polish** — Asking the AI to do simple things like add borders and implement the progress view for downloading.

### Prompt Examples

**Example 1 — Fix app entry point setup state**

> "The setupState in the main QCellsExerciseApp always shows neverLoaded even when I verify the state gets set to setUP via a breakpoint in the initalizer"

I had initially set the app setup state as an @State variable but the AI clued me into the fact it does not need to be a state variable and I did not even need the 'neverLoaded' setup state.

**Example 2 — Pagination implementation**

> "You see my ResourcesListView and ResourcesListViewModel? Can you implement the pagination that is now available in the DocumentsQuery inside the loadSourceData function?"

I initially loaded the whole list and then at the end just modified the GraphQL Query to allow pagination. After code generation I asked Codex to implement the pagination based on the new Query definition and it did a great job.

### Verification Process

- **Build verification** — all AI-suggested code was compiled immediately; type errors or missing APIs surfaced in Xcode and were corrected in the next prompt turn.
- **Logic review** — pagination and filtering logic was traced manually through the state machine to confirm edge cases (empty results, last-page detection, concurrent task guards).
- **Cache correctness** — thumbnail and PDF caching was verified by disabling network access in the simulator and confirming previously-loaded assets still render.

### Reflection

I think dealing with PDF's makes for a good demo of list and then detail view navigation. To make the list performant you can only pull the thumbnail for the PDF and then the detail view is naturally the whole PDF. This is relevent to a lot of products that might be PDF / documentation heavy as it provides a clean way to give the user access to these resources.
