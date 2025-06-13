import Buffer "mo:base/Buffer";
import Text "mo:base/Text";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Array "mo:base/Array";
import Swap "swap";
import Chat "mo:llm/chat";

module {
  public func generatePrompt(priceCache : Buffer.Buffer<Float>, swap : Swap.Swap, logs : Buffer.Buffer<Text>) : Text {
    let prompt = "prices=" # debug_show (Buffer.toArray(priceCache)) # "\n" #
    "ckBTC=" # debug_show (swap.getCkBTC()) # "\n" #
    "ckUSDC=" # debug_show (swap.getCkUSDC());
    logs.add("Prompt: \n" # prompt);
    return prompt;
  };

  public func performAction(response : Chat.Response, logs : Buffer.Buffer<Text>, priceCache : Buffer.Buffer<Float>, swap : Swap.Swap) {
    let responseContent = switch (response.message.content) {
      case (?content) content;
      case null {
        logs.add("No response");
        return;
      };
    };

    logs.add("Response: \n" # responseContent);

    // if the response contains "HOLD", do nothing
    if (Text.startsWith(responseContent, #text "HOLD")) {
      return;
    } else {
      let instructions = Iter.toArray(Text.split(responseContent, #text ","));
      if (Array.size(instructions) != 2) {
        return;
      };
      let token = instructions[0];
      let ?amount = Nat.fromText(instructions[1]) else {
        logs.add("Invalid amount");
        return;
      };

      ignore do ? {
        let price = priceCache.removeLast()!;
        swap.swap(token, amount, price);
      };

    };
    // empty the cache
    priceCache.clear();
  };
};
