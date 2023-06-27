import 'ConversationModel.dart';
import 'User.dart';

class HomeConversationModel {
  List<User> members = [];

  ConversationModel? conversationModel;

  HomeConversationModel({this.members = const [], this.conversationModel});
}
