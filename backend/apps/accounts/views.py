from django.contrib.auth import get_user_model
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.accounts.models import Profile
from apps.accounts.serializers import LoginSerializer, ProfileSerializer, ProfileUpdateSerializer, RegisterSerializer


User = get_user_model()


class RegisterView(generics.CreateAPIView):
    queryset = User.objects.all()
    serializer_class = RegisterSerializer
    permission_classes = [permissions.AllowAny]


class LoginView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        return Response(serializer.data, status=status.HTTP_200_OK)


class ProfileView(APIView):
    def get_object(self, request) -> Profile:
        profile, _ = Profile.objects.get_or_create(user=request.user)
        return profile

    def get(self, request):
        return Response(ProfileSerializer(self.get_object(request)).data)

    def patch(self, request):
        profile = self.get_object(request)
        serializer = ProfileUpdateSerializer(profile, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(ProfileSerializer(profile).data)
