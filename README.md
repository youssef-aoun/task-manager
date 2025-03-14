# **Task Manager**

## **Overview**
This is a **Ruby on Rails Task Manager Code** that allows users to **manage projects, tasks, and team memberships**.  
The API supports **authentication, role-based access, and pagination**.

---

## **Features**
 **User Authentication** (Register, Login, Logout)  
 **Project Management** (Create, Update, Delete, List)  
 **Task Management** (Assign, Update, Delete, List)  
 **Project Memberships** (Invite, Remove, List Members)  
 **Role-based Access Control** (Owner, Member, Assignee)  
 **Pagination Support**  
 **Comprehensive API Documentation with Apipie**

---

## **Tech Stack**
- **Ruby** 3.3.7
- **Rails** 8.0.1
- **PostgreSQL**
- **RSpec** (for testing)
- **JWT** (for authentication)
- **Apipie** (for API documentation)

---

## **API Endpoints**
### **Authentication**
| Method | Endpoint | Description |
|--------|---------|-------------|
| **POST** | `/api/v1/auth/register` | Register a new user |
| **POST** | `/api/v1/auth/login` | Log in and get a token |
| **DELETE** | `/api/v1/auth/logout` | Log out the user |

---

### **Users**
| Method | Endpoint | Description |
|--------|---------|-------------|
| **GET** | `/api/v1/users` | Get all users (paginated) |
| **GET** | `/api/v1/users/:id` | Get user details |
| **PUT** | `/api/v1/users/:id` | Update user profile |
| **DELETE** | `/api/v1/users` | Delete Profile |

---

### **Projects**
| Method | Endpoint | Description |
|--------|---------|-------------|
| **GET** | `/api/v1/projects` | Get all projects |
| **GET** | `/api/v1/projects/:id` | Get project details |
| **POST** | `/api/v1/projects` | Create a new project |
| **PUT** | `/api/v1/projects/:id` | Update a project |
| **DELETE** | `/api/v1/projects/:id` | Delete a project |

---

### **Tasks**
| Method | Endpoint | Description |
|--------|---------|-------------|
| **GET** | `/api/v1/projects/:project_id/tasks` | Get tasks for a project |
| **GET** | `/api/v1/projects/:project_id/tasks/:id` | Get a specific task |
| **POST** | `/api/v1/projects/:project_id/tasks` | Create a new task in a project |
| **PUT** | `/api/v1/projects/:project_id/tasks/:id` | Update a task |
| **DELETE** | `/api/v1/projects/:project_id/tasks/:id` | Delete a task |

---

### **Project Memberships**
| Method | Endpoint | Description |
|--------|---------|-------------|
| **GET** | `/api/v1/projects/:project_id/members` | List all project members |
| **POST** | `/api/v1/projects/:project_id/members` | Add a member to a project |
| **DELETE** | `/api/v1/projects/:project_id/members/:id` | Remove a member or leave a project |

---

## **API Documentation**
This API is documented using **Apipie**.
Open in your browser:
```
http://localhost:3000/apipie
```

