import Random "mo:base/Random";
import Float "mo:base/Float";
import Debug "mo:base/Debug";
import Nat "mo:base/Nat";
import Int "mo:base/Int";

module {
  public class Swap(initCkUSDC : Nat, initCkBTC : Nat) {

    var ckUSDC : Nat = initCkUSDC;
    var ckBTC : Nat = initCkBTC;

    /// Asynchronously generates a random positive Float in the range [0.0, 1.0).
    /// Traps if entropy cannot be obtained.
    public func fetchCurrentPrice() : async Float {
      let seed = await Random.blob();
      let r = Random.Finite(seed);

      let bits = switch (r.range(53)) {
        case (?val) val;
        case null {Debug.trap("Insufficient entropy for random float")}
      };

      let divisor = Float.pow(2.0, 53.0);
      Float.fromInt(bits) / divisor
    };

    /// Get current ckUSDC balance (in 6-decimal smallest units)
    public func getCkUSDC() : Nat {
      ckUSDC
    };

    /// Get current ckBTC balance (in 8-decimal smallest units)
    public func getCkBTC() : Nat {
      ckBTC
    };

    /// Perform a swap based on the token, amount, and price
    ///
    /// - token: "ckUSDC" or "ckBTC"
    /// - amount: amount of that token (in smallest units)
    /// - price: amount of ckBTC per 1.0 ckUSDC
    public func swap(token : Text, amount : Nat, price : Float) {
      if (token == "ckUSDC") {
        if (amount > ckUSDC) return;

        // Convert amount (Nat) to Float
        let ckUSDCFloat = Float.fromInt(amount);
        let ckBTCFloat = Float.mul(ckUSDCFloat / 1_000_000.0, price); // convert to full ckUSDC, then apply price
        let ckBTCAmount = Int.abs(Float.toInt(Float.mul(ckBTCFloat, 100_000_000.0))); // convert to smallest ckBTC units

        // Update balances
        ckUSDC -= amount;
        ckBTC += ckBTCAmount;

      } else if (token == "ckBTC") {
        if (amount > ckBTC) return;

        let ckBTCFloat = Float.fromInt(amount);
        let ckUSDCFloat = Float.div(ckBTCFloat / 100_000_000.0, price); // convert to full ckBTC, then apply price
        let ckUSDCAmount = Int.abs(Float.toInt(Float.mul(ckUSDCFloat, 1_000_000.0))); // convert to smallest ckUSDC units

        // Update balances
        ckBTC -= amount;
        ckUSDC += ckUSDCAmount;

      } else {
        // Invalid token, do nothing or trap
        return
      }
    };

  }

}
