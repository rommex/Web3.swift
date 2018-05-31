//
//  Contract.swift
//  Web3
//
//  Created by Koray Koska on 30.05.18.
//

import Foundation
#if !Web3CocoaPods
import Web3
#endif
import CryptoSwift

public protocol Contract {

    var contractDescriptionElements: [ContractDescriptionElement] { get }
}

public enum ContractCallError: Error {

    case functionMissing
    case inputsMalformed
    case internalError
}

public extension Contract {

    public func createTransactionData(name: String, inputs: [ContractTypeConvertible]) throws -> Bytes {
        guard let description = contractDescriptionElements.findFunctionDescription(with: name) else {
            throw ContractCallError.functionMissing
        }
        guard description.inputs.count == inputs.count else {
            throw ContractCallError.inputsMalformed
        }

        var signature = "\(name)("
        for i in description.inputs {
            signature += "\(i.signatureTypeString),"
        }
        if signature.hasSuffix(",") {
            signature = String(signature.dropLast())
        }
        signature += ")"
        let selectorHash = SHA3(variant: .keccak256).calculate(for: signature.data(using: .utf8)?.makeBytes() ?? [])
        var selector = Array(selectorHash[0..<4])
        for i in 0..<4 {
            if selectorHash.count > i {
                selector[i] = selectorHash[i]
            }
        }

        let encoding = ContractTypeTuple(types: inputs).encoding()

        var data = selector
        data.append(contentsOf: encoding)

        return data
    }
}