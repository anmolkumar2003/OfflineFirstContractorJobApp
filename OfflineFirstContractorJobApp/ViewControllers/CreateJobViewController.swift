//
//  CreateJobViewController.swift
//  OfflineFirstContractorJobApp
//
//  Created by mac on 10-01-2026.
//

import UIKit

protocol CreateJobDelegate: AnyObject {
    func jobCreated(_ job: Job)
}

class CreateJobViewController: UIViewController {
    
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var clientNameTextField: UITextField!
    @IBOutlet weak var cityTextField: UITextField!
    @IBOutlet weak var budgetTextField: UITextField!
    @IBOutlet weak var startDateTextField: UITextField!
    @IBOutlet weak var statusTextField: UITextField!
    @IBOutlet weak var createJobButton: UIButton!
    
    weak var delegate: CreateJobDelegate?
    var existingJob: Job?
    
    private let datePicker = UIDatePicker()
    private let statusPicker = UIPickerView()
    private let statusOptions = ["active", "pending", "completed"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        budgetTextField.keyboardType = .decimalPad
        setupDatePicker()
        setupStatusPicker()
        if let job = existingJob {
            loadJob(job)
            createJobButton.setTitle("Update Job", for: .normal)
            title = "Edit Job"
        }
    }
    
    private func setupDatePicker() {
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
        startDateTextField.inputView = datePicker
        
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneDatePicker))
        toolbar.setItems([doneButton], animated: false)
        startDateTextField.inputAccessoryView = toolbar
    }
    
    private func setupStatusPicker() {
        statusPicker.delegate = self
        statusPicker.dataSource = self
        statusTextField.inputView = statusPicker
        
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneStatusPicker))
        toolbar.setItems([doneButton], animated: false)
        statusTextField.inputAccessoryView = toolbar
    }
    
    @objc private func dateChanged() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        startDateTextField.text = formatter.string(from: datePicker.date)
    }
    
    @objc private func doneDatePicker() {
        dateChanged()
        startDateTextField.resignFirstResponder()
    }
    
    @objc private func doneStatusPicker() {
        let selectedRow = statusPicker.selectedRow(inComponent: 0)
        statusTextField.text = statusOptions[selectedRow].capitalized
        statusTextField.resignFirstResponder()
    }
    
    private func loadJob(_ job: Job) {
        titleTextField.text = job.title
        descriptionTextView.text = job.description
        clientNameTextField.text = job.clientName
        cityTextField.text = job.city
        budgetTextField.text = String(job.budget)
        startDateTextField.text = job.startDate
        statusTextField.text = job.status.displayName
    }
    
    private func validateInputs() -> Bool {
        guard let title = titleTextField.text?.trimmingCharacters(in: .whitespaces), !title.isEmpty else {
            showAlert(title: "Error", message: "Please enter job title")
            return false
        }
        
        guard let clientName = clientNameTextField.text?.trimmingCharacters(in: .whitespaces), !clientName.isEmpty else {
            showAlert(title: "Error", message: "Please enter client name")
            return false
        }
        
        guard let city = cityTextField.text?.trimmingCharacters(in: .whitespaces), !city.isEmpty else {
            showAlert(title: "Error", message: "Please enter city")
            return false
        }
        
        guard let budgetText = budgetTextField.text, !budgetText.isEmpty,
              let budget = Double(budgetText), budget > 0 else {
            showAlert(title: "Error", message: "Please enter a valid budget")
            return false
        }
        
        return true
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        createJobButton.applyGradient(
            colors: [
                UIColor(hex: "#3B82F6"),
                UIColor(hex: "#2563EB")
            ],
            cornerRadius: 16,
            shadowColor: UIColor(hex: "#3B82F6", alpha: 0.2)
        )
    }
    @IBAction func backButton(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    
    @IBAction func createJobButtonTapped(_ sender: UIButton) {
        guard validateInputs() else { return }
        
        let selectedStatus = statusOptions[statusPicker.selectedRow(inComponent: 0)]
        
        let jobRequest = JobRequest(
            title: titleTextField.text!.trimmingCharacters(in: .whitespaces),
            description: descriptionTextView.text.isEmpty ? nil : descriptionTextView.text,
            clientName: clientNameTextField.text!.trimmingCharacters(in: .whitespaces),
            city: cityTextField.text!.trimmingCharacters(in: .whitespaces),
            budget: Double(budgetTextField.text!)!,
            startDate: startDateTextField.text?.isEmpty == false ? startDateTextField.text : nil,
            status: selectedStatus
        )
        
        createJobButton.isEnabled = false
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.center = createJobButton.center
        view.addSubview(activityIndicator)
        activityIndicator.startAnimating()
        
        // Save locally first (offline-first)
        var newJob = Job(
            id: existingJob?.id,
            title: jobRequest.title,
            description: jobRequest.description,
            clientName: jobRequest.clientName,
            city: jobRequest.city,
            budget: jobRequest.budget,
            startDate: jobRequest.startDate,
            status: Job.JobStatus(rawValue: jobRequest.status) ?? .pending
        )
        
        if let existingJob = existingJob {
            newJob.localId = existingJob.localId
            newJob.syncStatus = .pending
        } else {
            newJob.syncStatus = .pending
        }
        
        LocalStorageManager.shared.saveJob(newJob)
        LocalStorageManager.shared.addPendingJob(newJob)
        
        // Try to sync if online
        if NetworkManager.shared.isConnected {
            if let jobId = existingJob?.id {
                APIService.shared.updateJob(id: jobId, jobRequest) { [weak self] result in
                    DispatchQueue.main.async {
                        activityIndicator.stopAnimating()
                        activityIndicator.removeFromSuperview()
                        self?.createJobButton.isEnabled = true
                        
                        switch result {
                        case .success(let updatedJob):
                            var syncedJob = updatedJob
                            syncedJob.localId = newJob.localId
                            syncedJob.syncStatus = .synced
                            LocalStorageManager.shared.saveJob(syncedJob)
                            LocalStorageManager.shared.removePendingJob(localId: newJob.localId)
                            self?.delegate?.jobCreated(syncedJob)
                            self?.navigationController?.popViewController(animated: true)
                        case .failure:
                            self?.delegate?.jobCreated(newJob)
                            self?.navigationController?.popViewController(animated: true)
                        }
                    }
                }
            } else {
                APIService.shared.createJob(jobRequest) { [weak self] result in
                    DispatchQueue.main.async {
                        activityIndicator.stopAnimating()
                        activityIndicator.removeFromSuperview()
                        self?.createJobButton.isEnabled = true
                        
                        switch result {
                        case .success(let createdJob):
                            var syncedJob = createdJob
                            syncedJob.localId = newJob.localId
                            syncedJob.syncStatus = .synced
                            LocalStorageManager.shared.saveJob(syncedJob)
                            LocalStorageManager.shared.removePendingJob(localId: newJob.localId)
                            self?.delegate?.jobCreated(syncedJob)
                            self?.navigationController?.popViewController(animated: true)
                        case .failure:
                            self?.delegate?.jobCreated(newJob)
                            self?.navigationController?.popViewController(animated: true)
                        }
                    }
                }
            }
        } else {
            // Offline - just save locally
            DispatchQueue.main.async {
                activityIndicator.stopAnimating()
                activityIndicator.removeFromSuperview()
                self.createJobButton.isEnabled = true
                self.delegate?.jobCreated(newJob)
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
}

// MARK: - UIPickerViewDataSource, UIPickerViewDelegate

extension CreateJobViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return statusOptions.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return statusOptions[row].capitalized
    }
}


