from rest_framework import serializers
from django.contrib.auth import get_user_model

User = get_user_model()


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=8)

    class Meta:
        model = User
        fields = ('id', 'email', 'full_name', 'password', 'role')

    def validate_role(self, value):
        valid = [User.ROLE_CAREGIVER, User.ROLE_PATIENT]
        if value not in valid:
            raise serializers.ValidationError(
                f"Role must be one of: {', '.join(valid)}"
            )
        return value

    def create(self, validated_data):
        user = User(
            email=validated_data['email'],
            username=validated_data['email'],
            full_name=validated_data['full_name'],
            role=validated_data.get('role', User.ROLE_PATIENT),
        )
        user.set_password(validated_data['password'])
        user.save()
        return user


class UserSerializer(serializers.ModelSerializer):
    name = serializers.CharField(source='full_name')

    class Meta:
        model = User
        fields = ('id', 'name', 'role')