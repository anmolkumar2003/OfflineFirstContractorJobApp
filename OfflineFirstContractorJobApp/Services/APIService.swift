//  APIService.swift
//  OfflineFirstContractorJobApp
//  Created by mac on 10-01-2026.

import Foundation

class APIService {
    static let shared = APIService()
    
    private let baseURL = "https://sandbox-job-app.bosselt.com"
    private let session = URLSession.shared
    
    private init() {}
    
    // MARK: - Helper Methods
    
    private func getAuthHeaders() -> [String: String] {
        var headers = ["Content-Type": "application/json"]
        if let token = UserDefaults.standard.string(forKey: "authToken") {
            headers["Authorization"] = "Bearer \(token)"
        }
        return headers
    }
    
    private func createRequest(url: URL, method: String, body: Data? = nil) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.allHTTPHeaderFields = getAuthHeaders()
        if let body = body {
            request.httpBody = body
        }
        return request
    }
    
    // MARK: - Authentication
    
    func signup(
        name: String,
        email: String,
        password: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)/api/v1/auth/register") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1)))
            return
        }

        let requestBody = AuthRequest(
            name: name,
            email: email,
            password: password
        )

        do {
            let bodyData = try JSONEncoder().encode(requestBody)

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = bodyData

            print("➡️ Signup URL:", url.absoluteString)
            print("➡️ Body:", String(data: bodyData, encoding: .utf8) ?? "")

            session.dataTask(with: request) { data, response, error in

                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.failure(NSError(domain: "Invalid response", code: -1)))
                    return
                }

                print("⬅️ Status:", httpResponse.statusCode)
                if let data = data {
                    print("⬅️ Response:", String(data: data, encoding: .utf8) ?? "")
                }

                if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                    // ✅ Signup successful (NO TOKEN HERE)
                    completion(.success(()))
                } else {
                    let message = data.flatMap {
                        String(data: $0, encoding: .utf8)
                    } ?? "Signup failed"

                    completion(.failure(
                        NSError(domain: message, code: httpResponse.statusCode)
                    ))
                }

            }.resume()

        } catch {
            completion(.failure(error))
        }
    }

    func login(
        email: String,
        password: String,
        completion: @escaping (Result<AuthUserData, Error>) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)/api/v1/auth/login") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1)))
            return
        }

        let requestBody = AuthRequest(
            name: nil,
            email: email,
            password: password
        )

        do {
            let bodyData = try JSONEncoder().encode(requestBody)

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = bodyData

            session.dataTask(with: request) { data, response, error in

                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse,
                      let data = data else {
                    completion(.failure(NSError(domain: "Invalid response", code: -1)))
                    return
                }

                print("⬅️ Login Status:", httpResponse.statusCode)
                print("⬅️ Login Response:", String(data: data, encoding: .utf8) ?? "")

                if httpResponse.statusCode == 200 {
                    do {
                        let apiResponse = try JSONDecoder().decode(AuthAPIResponse.self, from: data)

                        // 🔧 FIX 6: Save user data to persist login state
                        UserDefaults.standard.set(apiResponse.data.token, forKey: "authToken")
                        UserDefaults.standard.set(apiResponse.data.name, forKey: "userName")
                        UserDefaults.standard.set(apiResponse.data.email, forKey: "userEmail")
                        UserDefaults.standard.set(apiResponse.data.id, forKey: "userId")
                        UserDefaults.standard.set(true, forKey: "isLoggedIn")
                        UserDefaults.standard.synchronize()

                        completion(.success(apiResponse.data))
                    } catch {
                        completion(.failure(error))
                    }
                } else {
                    completion(.failure(
                        NSError(domain: "Login failed", code: httpResponse.statusCode)
                    ))
                }

            }.resume()
        } catch {
            completion(.failure(error))
        }
    }

    
    // MARK: - Jobs
    
    func getJobs(completion: @escaping (Result<[Job], Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/v1/jobs") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1)))
            return
        }

        let request = createRequest(url: url, method: "GET")

        session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: -1)))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NSError(domain: "Invalid response", code: -1)))
                return
            }

            // 🔍 DEBUG LOGS (VERY IMPORTANT)
            print("⬅️ STATUS:", httpResponse.statusCode)
            print("⬅️ RESPONSE:", String(data: data, encoding: .utf8) ?? "nil")

            switch httpResponse.statusCode {
            case 200:
                do {
                    let jobs = try JSONDecoder().decode([Job].self, from: data)
                    completion(.success(jobs))
                } catch {
                    completion(.failure(error))
                }

            case 401:
                completion(.failure(NSError(domain: "Unauthorized", code: 401)))

            default:
                let message = String(data: data, encoding: .utf8) ?? "Server error"
                completion(.failure(NSError(domain: message, code: httpResponse.statusCode)))
            }

        }.resume()
    }

    
    func createJob(_ job: JobRequest, completion: @escaping (Result<Job, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/v1/jobs") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1)))
            return
        }
        
        do {
            let data = try JSONEncoder().encode(job)
            let request = createRequest(url: url, method: "POST", body: data)
            
            session.dataTask(with: request) { data, response, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(NSError(domain: "No data", code: -1)))
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                        do {
                            let job = try JSONDecoder().decode(Job.self, from: data)
                            completion(.success(job))
                        } catch {
                            completion(.failure(error))
                        }
                    } else if httpResponse.statusCode == 401 {
                        completion(.failure(NSError(domain: "Unauthorized", code: 401)))
                    } else {
                        completion(.failure(NSError(domain: "HTTP Error", code: httpResponse.statusCode)))
                    }
                }
            }.resume()
        } catch {
            completion(.failure(error))
        }
    }
    
    func updateJob(id: String, _ job: JobRequest, completion: @escaping (Result<Job, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/v1/jobs/\(id)") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1)))
            return
        }
        
        do {
            let data = try JSONEncoder().encode(job)
            let request = createRequest(url: url, method: "PUT", body: data)
            
            session.dataTask(with: request) { data, response, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(NSError(domain: "No data", code: -1)))
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        do {
                            let job = try JSONDecoder().decode(Job.self, from: data)
                            completion(.success(job))
                        } catch {
                            completion(.failure(error))
                        }
                    } else if httpResponse.statusCode == 401 {
                        completion(.failure(NSError(domain: "Unauthorized", code: 401)))
                    } else {
                        completion(.failure(NSError(domain: "HTTP Error", code: httpResponse.statusCode)))
                    }
                }
            }.resume()
        } catch {
            completion(.failure(error))
        }
    }
    
    func getJob(id: String, completion: @escaping (Result<Job, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/v1/jobs/\(id)") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1)))
            return
        }
        
        let request = createRequest(url: url, method: "GET")
        
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: -1)))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    do {
                        let job = try JSONDecoder().decode(Job.self, from: data)
                        completion(.success(job))
                    } catch {
                        completion(.failure(error))
                    }
                } else if httpResponse.statusCode == 401 {
                    completion(.failure(NSError(domain: "Unauthorized", code: 401)))
                } else {
                    completion(.failure(NSError(domain: "HTTP Error", code: httpResponse.statusCode)))
                }
            }
        }.resume()
    }
    
    // MARK: - Notes
    
    func getNotes(jobId: String, completion: @escaping (Result<[Note], Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/v1/jobs/\(jobId)/notes") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1)))
            return
        }
        
        let request = createRequest(url: url, method: "GET")
        
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: -1)))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    do {
                        let notes = try JSONDecoder().decode([Note].self, from: data)
                        completion(.success(notes))
                    } catch {
                        completion(.failure(error))
                    }
                } else if httpResponse.statusCode == 401 {
                    completion(.failure(NSError(domain: "Unauthorized", code: 401)))
                } else {
                    completion(.failure(NSError(domain: "HTTP Error", code: httpResponse.statusCode)))
                }
            }
        }.resume()
    }
    
    func createNote(jobId: String, content: String, completion: @escaping (Result<Note, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/v1/jobs/\(jobId)/notes") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1)))
            return
        }
        
        let requestBody = NoteRequest(content: content)
        
        do {
            let data = try JSONEncoder().encode(requestBody)
            let request = createRequest(url: url, method: "POST", body: data)
            
            session.dataTask(with: request) { data, response, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(NSError(domain: "No data", code: -1)))
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                        do {
                            let note = try JSONDecoder().decode(Note.self, from: data)
                            completion(.success(note))
                        } catch {
                            completion(.failure(error))
                        }
                    } else if httpResponse.statusCode == 401 {
                        completion(.failure(NSError(domain: "Unauthorized", code: 401)))
                    } else {
                        completion(.failure(NSError(domain: "HTTP Error", code: httpResponse.statusCode)))
                    }
                }
            }.resume()
        } catch {
            completion(.failure(error))
        }
    }
    
    func updateNote(jobId: String, noteId: String, content: String, completion: @escaping (Result<Note, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/v1/jobs/\(jobId)/notes/\(noteId)") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1)))
            return
        }
        
        let requestBody = NoteRequest(content: content)
        
        do {
            let data = try JSONEncoder().encode(requestBody)
            let request = createRequest(url: url, method: "PUT", body: data)
            
            session.dataTask(with: request) { data, response, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(NSError(domain: "No data", code: -1)))
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        do {
                            let note = try JSONDecoder().decode(Note.self, from: data)
                            completion(.success(note))
                        } catch {
                            completion(.failure(error))
                        }
                    } else if httpResponse.statusCode == 401 {
                        completion(.failure(NSError(domain: "Unauthorized", code: 401)))
                    } else {
                        completion(.failure(NSError(domain: "HTTP Error", code: httpResponse.statusCode)))
                    }
                }
            }.resume()
        } catch {
            completion(.failure(error))
        }
    }
    
    // MARK: - Video Upload
    
    func uploadVideo(jobId: String, videoData: Data, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/v1/jobs/\(jobId)/video") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("video/mp4", forHTTPHeaderField: "Content-Type")
        if let token = UserDefaults.standard.string(forKey: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = videoData
        
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                    completion(.success(()))
                } else if httpResponse.statusCode == 401 {
                    completion(.failure(NSError(domain: "Unauthorized", code: 401)))
                } else {
                    completion(.failure(NSError(domain: "HTTP Error", code: httpResponse.statusCode)))
                }
            }
        }.resume()
    }
}
