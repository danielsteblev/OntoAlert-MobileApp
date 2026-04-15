from django.contrib.auth import authenticate, get_user_model
from rest_framework import serializers
from rest_framework_simplejwt.tokens import RefreshToken

from apps.accounts.models import Profile


User = get_user_model()


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ("id", "username", "email")


class ProfileSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)

    class Meta:
        model = Profile
        fields = ("user", "full_name", "bio", "university", "avatar_url")


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=6)
    full_name = serializers.CharField(write_only=True, required=False, allow_blank=True)

    class Meta:
        model = User
        fields = ("username", "email", "password", "full_name")

    def create(self, validated_data):
        full_name = validated_data.pop("full_name", "")
        user = User.objects.create_user(**validated_data)
        Profile.objects.create(user=user, full_name=full_name)
        return user

    def to_representation(self, instance):
        tokens = RefreshToken.for_user(instance)
        return {
            "user": UserSerializer(instance).data,
            "profile": ProfileSerializer(instance.profile).data,
            "tokens": {
                "access": str(tokens.access_token),
                "refresh": str(tokens),
            },
        }


class LoginSerializer(serializers.Serializer):
    username = serializers.CharField()
    password = serializers.CharField(write_only=True)

    def validate(self, attrs):
        user = authenticate(username=attrs["username"], password=attrs["password"])
        if not user:
            raise serializers.ValidationError("Invalid username or password.")
        attrs["user"] = user
        return attrs

    def to_representation(self, instance):
        user = instance["user"]
        tokens = RefreshToken.for_user(user)
        return {
            "user": UserSerializer(user).data,
            "profile": ProfileSerializer(user.profile).data,
            "tokens": {
                "access": str(tokens.access_token),
                "refresh": str(tokens),
            },
        }


class ProfileUpdateSerializer(serializers.ModelSerializer):
    email = serializers.EmailField(source="user.email", required=False)

    class Meta:
        model = Profile
        fields = ("full_name", "bio", "university", "avatar_url", "email")

    def update(self, instance, validated_data):
        user_data = validated_data.pop("user", {})
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        for attr, value in user_data.items():
            setattr(instance.user, attr, value)
        instance.user.save(update_fields=list(user_data.keys()) or None)
        instance.save()
        return instance
