import LLM "mo:llm";
import Prompt "prompt";
import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Timer "mo:base/Timer";
import Text "mo:base/Text";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";

import Swap "swap";

actor {
  let swap = Swap.Swap(10000000000, 0);

  var priceCache : Buffer.Buffer<Float> = Buffer.Buffer<Float>(0);
  var logCache : Buffer.Buffer<Text> = Buffer.Buffer<Text>(0);

  ignore Timer.recurringTimer<system>(
    #seconds 6,
    func() : async () {
      // check the amount of ckBTC we can swap for 1 ckUSDC from the mockup implementation
      let currentPrice = await swap.fetchCurrentPrice();
      priceCache.add(currentPrice);
      logCache.add("Current price: " # debug_show (currentPrice))
    }
  );

  ignore Timer.recurringTimer<system>(
    #seconds 36,
    func() : async () {

      // prepare the message for the LLM
      let content = "prices=" # debug_show (Buffer.toArray(priceCache)) # "\n" #
      "ckBTC=" # debug_show (swap.getCkBTC()) # "\n" #
      "ckUSDC=" # debug_show (swap.getCkUSDC()) # "\n";

      logCache.add("Prompt: \n" # content);

      let response = await LLM.chat(#Llama3_1_8B).withMessages([
        #system_ {
          content = Prompt.SYSTEM_PROMPT
        },
        #user {
          content
        }
      ]).send();

      let responseContent = switch (response.message.content) {
        case (?content) content;
        case null {
          logCache.add("No response");
          return
        }
      };

      logCache.add("Response: \n" # responseContent);

      // if the response contains "HOLD", do nothing
      if (Text.startsWith(responseContent, #text "HOLD")) {
        return
      } else {
        let instructions = Iter.toArray(Text.split(responseContent, #text ","));
        if (Array.size(instructions) != 2) {
          return
        };
        let token = instructions[0];
        let ?amount = Nat.fromText(instructions[1]) else {
          logCache.add("Invalid amount");
          return
        };

        ignore do ? {
          let price = priceCache.removeLast()!;
          swap.swap(token, amount, price)
        };

      };
      // empty the cache
      priceCache.clear()
    }
  );

  public func getLogs() : async [Text] {
    Buffer.toArray(logCache)
  }

}
