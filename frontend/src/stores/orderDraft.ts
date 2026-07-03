import { computed, ref, watch } from 'vue'
import { defineStore } from 'pinia'

export type Address = {
  receiver: string
  phone: string
  region: string
  detail: string
}

export type PaymentStatus = 'INIT' | 'PROCESSING' | 'SUCCESS' | 'FAILED'

type OrderDraftV1 = {
  v: 1
  orderId: string | null
  address: Address | null
  invoiceTitle: string
  deliveryMethod: 'express'
  couponCode: string
  usePoints: number
  amounts: {
    items: number
    discount: number
    shipping: number
    payable: number
  } | null
  payment: {
    status: PaymentStatus
    paidAt: string | null
    failureReason: string | null
  }
}

const STORAGE_KEY = 'orderDraft:v1'

const readSnapshot = (): OrderDraftV1 => {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    if (!raw) {
      return {
        v: 1,
        orderId: null,
        address: null,
        invoiceTitle: '',
        deliveryMethod: 'express',
        couponCode: '',
        usePoints: 0,
        amounts: null,
        payment: { status: 'INIT', paidAt: null, failureReason: null },
      }
    }
    const parsed = JSON.parse(raw) as OrderDraftV1
    if (parsed?.v !== 1) throw new Error('version mismatch')
    return parsed
  } catch {
    return {
      v: 1,
      orderId: null,
      address: null,
      invoiceTitle: '',
      deliveryMethod: 'express',
      couponCode: '',
      usePoints: 0,
      amounts: null,
      payment: { status: 'INIT', paidAt: null, failureReason: null },
    }
  }
}

const oid = () => `o_${Math.random().toString(16).slice(2)}_${Date.now().toString(16)}`

export const useOrderDraftStore = defineStore('orderDraft', () => {
  const draft = ref<OrderDraftV1>(readSnapshot())

  const orderId = computed(() => draft.value.orderId)
  const paymentStatus = computed(() => draft.value.payment.status)

  const setAddress = (addr: Address) => {
    draft.value.address = addr
  }

  const setCouponCode = (code: string) => {
    draft.value.couponCode = code
  }

  const setInvoiceTitle = (title: string) => {
    draft.value.invoiceTitle = title
  }

  const setUsePoints = (points: number) => {
    draft.value.usePoints = Math.max(0, Math.floor(points))
  }

  const reset = () => {
    draft.value = {
      v: 1,
      orderId: null,
      address: null,
      invoiceTitle: '',
      deliveryMethod: 'express',
      couponCode: '',
      usePoints: 0,
      amounts: null,
      payment: { status: 'INIT', paidAt: null, failureReason: null },
    }
  }

  const createOrder = (input: {
    orderId?: string
    itemsAmount: number
    discount: number
    shipping: number
    payable?: number
  }) => {
    const payable = typeof input.payable === 'number' ? input.payable : Math.max(0, input.itemsAmount - input.discount + input.shipping)
    draft.value.orderId = input.orderId || oid()
    draft.value.amounts = {
      items: input.itemsAmount,
      discount: input.discount,
      shipping: input.shipping,
      payable,
    }
    draft.value.payment = { status: 'INIT', paidAt: null, failureReason: null }
    return draft.value.orderId
  }

  const setInit = () => {
    draft.value.payment = { status: 'INIT', paidAt: null, failureReason: null }
  }

  const markPaid = (paidAtIso: string) => {
    draft.value.payment = { status: 'SUCCESS', paidAt: paidAtIso, failureReason: null }
  }

  const markFailed = (reason: string) => {
    draft.value.payment = { status: 'FAILED', paidAt: null, failureReason: reason }
  }

  const setProcessing = () => {
    draft.value.payment = { status: 'PROCESSING', paidAt: null, failureReason: null }
  }

  const loadFromBackend = (data: any) => {
    const id = String(data.id ?? data.orderId ?? '')
    const total = Number(data.totalAmount ?? 0)
    const pay = Number(data.payAmount ?? 0)
    const discount = Number(data.discountAmount ?? 0)
    const shipping = Number(data.shippingAmount ?? 0)

    draft.value.orderId = id
    draft.value.amounts = {
      items: total,
      discount: discount,
      shipping: shipping,
      payable: pay || Math.max(0, total - discount + shipping),
    }
    draft.value.address = {
      receiver: String(data.receiverName ?? ''),
      phone: String(data.receiverPhone ?? ''),
      region: String(data.receiverRegion ?? ''),
      detail: String(data.receiverDetail ?? ''),
    }
    draft.value.invoiceTitle = String(data.invoiceTitle ?? '')
    draft.value.couponCode = String(data.couponCode ?? '')

    const st = data.status
    if (st === 1 || st === 'Paid') {
      draft.value.payment = { status: 'SUCCESS', paidAt: data.payTime || new Date().toISOString(), failureReason: null }
    } else if (st === 4 || st === 'Cancelled') {
      draft.value.payment = { status: 'FAILED', paidAt: null, failureReason: '订单已取消' }
    } else {
      draft.value.payment = { status: 'INIT', paidAt: null, failureReason: null }
    }
  }

  watch(
    draft,
    (v) => {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(v))
    },
    { deep: true },
  )

  return {
    draft,
    orderId,
    paymentStatus,
    setAddress,
    setCouponCode,
    setInvoiceTitle,
    setUsePoints,
    createOrder,
    setInit,
    markPaid,
    markFailed,
    setProcessing,
    loadFromBackend,
    reset,
  }
})
