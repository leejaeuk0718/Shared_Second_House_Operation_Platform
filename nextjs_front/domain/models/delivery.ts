// domain/models/delivery.ts

export interface ShDeliveryData {
  orderId: number;
  userId: number;
  deliveryAddress: string;
  totalAmount: number;
  status: string;
  createdAt?: string;
}