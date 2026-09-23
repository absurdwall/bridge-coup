#include <charconv>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>

#include <dds/dds.h>

namespace {

std::vector<std::string> split(const std::string& value, const char delimiter) {
  std::vector<std::string> parts;
  std::size_t start = 0;
  while (true) {
    const std::size_t end = value.find(delimiter, start);
    if (end == std::string::npos) {
      parts.push_back(value.substr(start));
      return parts;
    }
    parts.push_back(value.substr(start, end - start));
    start = end + 1;
  }
}

bool parse_int(const std::string& value, int& result) {
  const char* begin = value.data();
  const char* end = begin + value.size();
  const auto parsed = std::from_chars(begin, end, result);
  return parsed.ec == std::errc{} && parsed.ptr == end;
}

int parse_rank(const char value) {
  if (value >= '2' && value <= '9') return value - '0';
  switch (value) {
    case 'T': return 10;
    case 'J': return 11;
    case 'Q': return 12;
    case 'K': return 13;
    case 'A': return 14;
    default: return 0;
  }
}

bool parse_hand(const std::string& value, unsigned int (&holding)[DDS_SUITS]) {
  const auto suits = split(value, '.');
  if (suits.size() != DDS_SUITS) return false;

  for (int suit = 0; suit < DDS_SUITS; ++suit) {
    for (const char rank_char : suits[suit]) {
      const int rank = parse_rank(rank_char);
      if (rank < 2 || rank > 14) return false;
      const unsigned int card = 1u << rank;
      if ((holding[suit] & card) != 0) return false;
      holding[suit] |= card;
    }
  }
  return true;
}

bool parse_trick_card(const std::string& value, int& suit, int& rank) {
  if (value.size() < 3 || value[1] != ':') return false;
  if (!parse_int(value.substr(0, 1), suit) || suit < 0 || suit >= DDS_SUITS) return false;
  const std::string rank_text = value.substr(2);
  if (!parse_int(rank_text, rank) || rank < 2 || rank > 14) return false;
  return true;
}

int fail(const std::string& message) {
  std::cerr << message << '\n';
  return 1;
}

}  // namespace

int main(int argc, char** argv) {
  if (argc != 2 || std::string(argv[1]) != "--bridge-teacher-dds-wire-v1") {
    return fail("Expected the Bridge Teacher DDS wire protocol flag.");
  }

  std::string line;
  if (!std::getline(std::cin, line)) return fail("No DDS position was provided.");
  const auto fields = split(line, '|');
  if (fields.size() != 7) return fail("DDS position must contain seven fields.");

  Deal deal{};
  if (!parse_int(fields[0], deal.trump) || deal.trump < 0 || deal.trump > 4) {
    return fail("Trump encoding is outside 0...4.");
  }
  if (!parse_int(fields[1], deal.first) || deal.first < 0 || deal.first >= DDS_HANDS) {
    return fail("Leader encoding is outside 0...3.");
  }

  for (int card = 0; card < 3; ++card) {
    deal.currentTrickSuit[card] = 0;
    deal.currentTrickRank[card] = 0;
  }
  if (!fields[2].empty()) {
    const auto cards = split(fields[2], ',');
    if (cards.size() > 3) return fail("Current trick contains more than three played cards.");
    for (std::size_t index = 0; index < cards.size(); ++index) {
      if (!parse_trick_card(cards[index], deal.currentTrickSuit[index], deal.currentTrickRank[index])) {
        return fail("Current trick card encoding is invalid.");
      }
    }
  }

  for (int hand = 0; hand < DDS_HANDS; ++hand) {
    if (!parse_hand(fields[hand + 3], deal.remainCards[hand])) {
      return fail("A hand has invalid PBN suit holdings.");
    }
  }

  // DDS documents SetMaxThreads(0) as required initialization on macOS.
  SetMaxThreads(0);

  FutureTricks future{};
  const int error = SolveBoard(deal, -1, 3, 0, &future, 0);
  if (error != RETURN_NO_FAULT) {
    char message[80] = {};
    ErrorMessage(error, message);
    return fail(std::string("DDS SolveBoard failed: ") + message);
  }
  if (future.cards < 1 || future.cards > 13) return fail("DDS returned an invalid legal-card count.");

  std::cout << "{\"moves\":[";
  for (int index = 0; index < future.cards; ++index) {
    if (index != 0) std::cout << ',';
    std::cout << "{\"suit\":" << future.suit[index]
              << ",\"rank\":" << future.rank[index]
              << ",\"equals\":" << future.equals[index]
              << ",\"tricks\":" << future.score[index] << '}';
  }
  std::cout << "]}\n";
  return 0;
}
