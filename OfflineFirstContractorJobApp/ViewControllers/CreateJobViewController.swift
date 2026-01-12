//  CreateJobViewController.swift
//  OfflineFirstContractorJobApp

import UIKit

protocol CreateJobDelegate: AnyObject {
    func jobCreated(_ job: Job)
}

final class CreateJobViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var createJobLabel: UILabel!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var clientNameTextField: UITextField!
    @IBOutlet weak var cityTextField: UITextField!
    @IBOutlet weak var budgetTextField: UITextField!
    @IBOutlet weak var startDateTextField: UITextField!
    @IBOutlet weak var statusTextField: UITextField!
    @IBOutlet weak var createJobButton: UIButton!

    // MARK: - Properties

    weak var delegate: CreateJobDelegate?
    var existingJob: Job?

    private let datePicker = UIDatePicker()
    private let statusPicker = UIPickerView()
    private let statusOptions = ["active", "pending", "completed"]

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        budgetTextField.keyboardType = .decimalPad
        setupDatePicker()
        setupStatusPicker()
        setupTextFieldDelegates()
    
        if let job = existingJob {
            createJobLabel.text = "Edit Job"
            createJobButton.setTitle("Update Job", for: .normal)
            loadJob(job)
        } else {
            createJobLabel.text = "Create Job"
            createJobButton.setTitle("Create Job", for: .normal)
        }
        
        // Add tap gesture to dismiss keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
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

    // MARK: - Setup

    private func setupDatePicker() {
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
        startDateTextField.inputView = datePicker

        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        toolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(barButtonSystemItem: .done,
                            target: self,
                            action: #selector(doneDatePicker))
        ]
        startDateTextField.inputAccessoryView = toolbar
    }

    private func setupStatusPicker() {
        statusPicker.delegate = self
        statusPicker.dataSource = self
        statusTextField.inputView = statusPicker

        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        toolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(barButtonSystemItem: .done,
                            target: self,
                            action: #selector(doneStatusPicker))
        ]
        statusTextField.inputAccessoryView = toolbar
    }
    
    private func setupTextFieldDelegates() {
        titleTextField.delegate = self
        clientNameTextField.delegate = self
        cityTextField.delegate = self
        budgetTextField.delegate = self
        startDateTextField.delegate = self
        statusTextField.delegate = self
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    // MARK: - Actions

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

    @IBAction func backButton(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }

    @IBAction func createJobButtonTapped(_ sender: UIButton) {
        guard validateInputs() else { return }

        let selectedStatus = statusOptions[statusPicker.selectedRow(inComponent: 0)]
        let desc = descriptionTextView.text?.trimmingCharacters(in: .whitespaces)
        let finalDescription = desc?.isEmpty == true ? nil : desc

        var job: Job
        if var editingJob = existingJob {
            // UPDATE EXISTING JOB - keep same localId and id
            editingJob.title = titleTextField.text!.trimmed()
            editingJob.description = finalDescription
            editingJob.clientName = clientNameTextField.text!.trimmed()
            editingJob.city = cityTextField.text!.trimmed()
            editingJob.budget = Double(budgetTextField.text!)!
            editingJob.startDate = startDateTextField.text
            editingJob.status = Job.JobStatus(rawValue: selectedStatus) ?? .pending
            if editingJob.id != nil && editingJob.syncStatus == .synced {
                editingJob.syncStatus = .pending
            } else if editingJob.id == nil {
                editingJob.syncStatus = .pending
            }
            
            job = editingJob
        } else {
            // CREATE NEW JOB
            job = Job(
                id: nil,
                title: titleTextField.text!.trimmed(),
                description: finalDescription,
                clientName: clientNameTextField.text!.trimmed(),
                city: cityTextField.text!.trimmed(),
                budget: Double(budgetTextField.text!)!,
                startDate: startDateTextField.text,
                status: Job.JobStatus(rawValue: selectedStatus) ?? .pending
            )
            job.localId = UUID().uuidString
            job.syncStatus = .pending
        }

        // Save to local storage
        LocalStorageManager.shared.saveJob(job)
        
        // Trigger sync
        SyncManager.shared.triggerSync()

        // Notify delegate
        delegate?.jobCreated(job)

        // Navigate back
        if let nav = navigationController {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    // MARK: - Helpers

    private func loadJob(_ job: Job) {
        titleTextField.text = job.title
        descriptionTextView.text = job.description
        clientNameTextField.text = job.clientName
        cityTextField.text = job.city
        budgetTextField.text = String(job.budget)
        startDateTextField.text = job.startDate
        statusTextField.text = job.status.displayName
        
        // Set the picker to the correct status
        if let index = statusOptions.firstIndex(of: job.status.rawValue) {
            statusPicker.selectRow(index, inComponent: 0, animated: false)
        }
    }

    private func validateInputs() -> Bool {
        guard let title = titleTextField.text?.trimmed(), !title.isEmpty else {
            showAlert("Please enter job title")
            return false
        }

        guard let clientName = clientNameTextField.text?.trimmed(), !clientName.isEmpty else {
            showAlert("Please enter client name")
            return false
        }

        guard let city = cityTextField.text?.trimmed(), !city.isEmpty else {
            showAlert("Please enter city")
            return false
        }

        guard let budgetText = budgetTextField.text,
              let budget = Double(budgetText), budget > 0 else {
            showAlert("Please enter valid budget")
            return false
        }

        return true
    }

    private func showAlert(_ message: String) {
        let alert = UIAlertController(title: "Error",
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UIPickerView

extension CreateJobViewController: UIPickerViewDataSource, UIPickerViewDelegate {

    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }

    func pickerView(_ pickerView: UIPickerView,
                    numberOfRowsInComponent component: Int) -> Int {
        statusOptions.count
    }

    func pickerView(_ pickerView: UIPickerView,
                    titleForRow row: Int,
                    forComponent component: Int) -> String? {
        statusOptions[row].capitalized
    }
}

// 🔧 FIX 3: UITextFieldDelegate for return key
extension CreateJobViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case titleTextField:
            clientNameTextField.becomeFirstResponder()
        case clientNameTextField:
            cityTextField.becomeFirstResponder()
        case cityTextField:
            budgetTextField.becomeFirstResponder()
        case budgetTextField:
            startDateTextField.becomeFirstResponder()
        default:
            textField.resignFirstResponder()
        }
        return true
    }
}

// MARK: - String Helper

private extension String {
    func trimmed() -> String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
