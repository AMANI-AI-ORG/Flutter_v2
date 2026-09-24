//
//  SignatureCapture.swift
//  flutter_amanisdk
//

import AmaniSDK
import Flutter
import UIKit

/// Flutter bridge for the Core SDK's Signature module.
///
/// The Core SDK only provides the drawing canvas, so this class builds the screen
/// around it: a title, a counter for multi-signature flows, and Clear / Confirm /
/// Close buttons. The controls are siblings of the SDK view, so they never appear
/// in the signature image the SDK captures.
class SignatureCapture: NSObject {
  private let module = Amani.sharedInstance.signature()
  private var container: UIView?
  private var confirmButton: UIButton?
  private var counterLabel: UILabel?
  private var pendingResult: FlutterResult?

  func start(arguments: [String: Any]?, result: @escaping FlutterResult) {
    let settings = SignatureFlutterSettings(arguments: arguments)

    DispatchQueue.main.async { [weak self] in
      guard let self else { return }
      guard let vc = UIApplication.shared.windows.last?.rootViewController else {
        result(FlutterError(code: "30050", message: "Could not find a view controller to present the signature screen.", details: nil))
        return
      }

      self.dismiss()
      self.pendingResult = result

      let container = UIView(frame: vc.view.bounds)
      container.backgroundColor = .white
      container.autoresizingMask = [.flexibleWidth, .flexibleHeight]

      self.module.setViewArea(viewArea: container.bounds)
      self.module.setConfirmButtonCallback { [weak self] in
        self?.setConfirmEnabled(true)
      }
      self.module.setOnConfirmPressedCallback { [weak self] _, signatureNumber in
        print("[AmaniBridge][Signature] signature \(signatureNumber) of \(settings.count) confirmed")
        self?.setConfirmEnabled(false)
        self?.updateCounter(completed: signatureNumber, total: settings.count)
      }

      do {
        guard let signatureView = try self.module.start(stepId: settings.count, completion: { [weak self] image in
          self?.finish(with: image)
        }) else {
          self.pendingResult = nil
          result(FlutterError(code: "30051", message: "Signature document configuration was not found for this customer.", details: nil))
          return
        }

        container.addSubview(signatureView)
        self.addControls(to: container, settings: settings)
        vc.view.addSubview(container)
        vc.view.bringSubviewToFront(container)
        self.container = container
        self.updateCounter(completed: 0, total: settings.count)
        self.setConfirmEnabled(false)
        print("[AmaniBridge][Signature] started, expecting \(settings.count) signature(s)")
      } catch let err {
        self.pendingResult = nil
        result(FlutterError(code: "30007", message: err.localizedDescription, details: nil))
      }
    }
  }

  func upload(result: @escaping FlutterResult) {
    module.upload { isSuccess in
      DispatchQueue.main.async {
        result(isSuccess)
      }
    }
  }

  /// Uploads the captured signatures and returns {"isSuccess": Bool, "documentId": String?}.
  func uploadWithDocumentId(result: @escaping FlutterResult) {
    module.upload { (isSuccess: Bool?, documentId: String?) in
      UploadResultPayload.send(isSuccess: isSuccess, documentId: documentId, module: "Signature", to: result)
    }
  }

  // MARK: - Flow

  private func finish(with image: UIImage) {
    DispatchQueue.main.async { [weak self] in
      guard let self, let result = self.pendingResult else { return }
      self.pendingResult = nil
      if let data = image.pngData() {
        result(FlutterStandardTypedData(bytes: data))
      } else {
        result(FlutterError(code: "30052", message: "Could not encode the signature image.", details: nil))
      }
      self.dismiss()
    }
  }

  @objc private func onClose() {
    print("[AmaniBridge][Signature] cancelled by the user")
    let result = pendingResult
    pendingResult = nil
    dismiss()
    result?(FlutterError(code: "30053", message: "Signature capture was cancelled by the user.", details: nil))
  }

  @objc private func onClear() {
    module.clear()
    setConfirmEnabled(false)
  }

  @objc private func onConfirm() {
    module.capture()
  }

  private func dismiss() {
    container?.removeFromSuperview()
    container = nil
    confirmButton = nil
    counterLabel = nil
  }

  private func setConfirmEnabled(_ enabled: Bool) {
    DispatchQueue.main.async { [weak self] in
      self?.confirmButton?.isEnabled = enabled
      self?.confirmButton?.alpha = enabled ? 1.0 : 0.4
    }
  }

  private func updateCounter(completed: Int, total: Int) {
    DispatchQueue.main.async { [weak self] in
      guard let label = self?.counterLabel else { return }
      label.isHidden = total <= 1
      label.text = "\(min(completed + 1, total)) / \(total)"
    }
  }

  // MARK: - Layout

  private func addControls(to container: UIView, settings: SignatureFlutterSettings) {
    let titleLabel = UILabel()
    titleLabel.text = settings.title
    titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
    titleLabel.textColor = .darkGray
    titleLabel.textAlignment = .center
    titleLabel.numberOfLines = 0

    let counterLabel = UILabel()
    counterLabel.font = .systemFont(ofSize: 15, weight: .medium)
    counterLabel.textColor = .gray
    counterLabel.textAlignment = .center
    self.counterLabel = counterLabel

    let closeButton = UIButton(type: .system)
    closeButton.setImage(ImageProvider.image(named: "xmark"), for: .normal)
    closeButton.tintColor = .darkGray
    closeButton.addTarget(self, action: #selector(onClose), for: .touchUpInside)

    let baseline = UIView()
    baseline.backgroundColor = UIColor.lightGray.withAlphaComponent(0.6)
    baseline.isUserInteractionEnabled = false

    let clearButton = makeButton(title: settings.clearButtonText, filled: false, color: settings.buttonColor)
    clearButton.addTarget(self, action: #selector(onClear), for: .touchUpInside)

    let confirmButton = makeButton(title: settings.confirmButtonText, filled: true, color: settings.buttonColor)
    confirmButton.addTarget(self, action: #selector(onConfirm), for: .touchUpInside)
    self.confirmButton = confirmButton

    let buttons = UIStackView(arrangedSubviews: [clearButton, confirmButton])
    buttons.axis = .horizontal
    buttons.spacing = 12
    buttons.distribution = .fillEqually

    for view in [titleLabel, counterLabel, closeButton, baseline, buttons] as [UIView] {
      view.translatesAutoresizingMaskIntoConstraints = false
      container.addSubview(view)
    }

    let guide = container.safeAreaLayoutGuide
    NSLayoutConstraint.activate([
      closeButton.topAnchor.constraint(equalTo: guide.topAnchor, constant: 8),
      closeButton.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -12),
      closeButton.widthAnchor.constraint(equalToConstant: 44),
      closeButton.heightAnchor.constraint(equalToConstant: 44),

      titleLabel.topAnchor.constraint(equalTo: guide.topAnchor, constant: 18),
      titleLabel.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 60),
      titleLabel.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -60),

      counterLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
      counterLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),

      baseline.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 32),
      baseline.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -32),
      baseline.bottomAnchor.constraint(equalTo: buttons.topAnchor, constant: -80),
      baseline.heightAnchor.constraint(equalToConstant: 1),

      buttons.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 16),
      buttons.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -16),
      buttons.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -16),
      buttons.heightAnchor.constraint(equalToConstant: 50),
    ])
  }

  private func makeButton(title: String, filled: Bool, color: UIColor) -> UIButton {
    let button = UIButton(type: .system)
    button.setTitle(title, for: .normal)
    button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
    button.layer.cornerRadius = 10
    button.layer.borderWidth = filled ? 0 : 1.5
    button.layer.borderColor = color.cgColor
    button.backgroundColor = filled ? color : .white
    button.setTitleColor(filled ? .white : color, for: .normal)
    return button
  }
}

// MARK: - Flutter-side settings

private struct SignatureFlutterSettings {
  let count: Int
  let title: String
  let clearButtonText: String
  let confirmButtonText: String
  let buttonColor: UIColor

  init(arguments: [String: Any]?) {
    count = max(1, arguments?["count"] as? Int ?? 1)
    title = arguments?["title"] as? String ?? "Please sign in the area below"
    clearButtonText = arguments?["clearButtonText"] as? String ?? "Clear"
    confirmButtonText = arguments?["confirmButtonText"] as? String ?? "Confirm"
    buttonColor = UIColor(signatureHex: arguments?["buttonColor"] as? String) ?? .systemBlue
  }
}

private extension UIColor {
  convenience init?(signatureHex hex: String?) {
    guard var hex = hex?.trimmingCharacters(in: .whitespacesAndNewlines) else { return nil }
    if hex.hasPrefix("#") { hex.removeFirst() }
    guard hex.count == 6, let value = UInt32(hex, radix: 16) else { return nil }
    self.init(
      red: CGFloat((value & 0xFF0000) >> 16) / 255.0,
      green: CGFloat((value & 0x00FF00) >> 8) / 255.0,
      blue: CGFloat(value & 0x0000FF) / 255.0,
      alpha: 1.0
    )
  }
}
